const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {setGlobalOptions} = require('firebase-functions/v2');
const {logger} = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({region: 'us-central1', maxInstances: 10});

const MIN_PASSWORD_LENGTH = 8;

function isAcceptablePassword(password) {
  if (typeof password !== 'string') return false;
  if (password.length < MIN_PASSWORD_LENGTH || password.length > 128) return false;
  if (/\s/.test(password)) return false;
  return /[A-Za-z]/.test(password) && /[0-9]/.test(password);
}

exports.resetUserPassword = onCall(
  {
    cors: true,
    invoker: 'public'
  },
  async (request) => {
    try {
      if (!request.auth || !request.auth.uid) {
        throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول');
      }

      const targetUid = typeof request.data?.uid === 'string' ? request.data.uid.trim() : '';
      const newPassword = typeof request.data?.newPassword === 'string' ? request.data.newPassword : '';

      if (!targetUid) {
        throw new HttpsError('invalid-argument', 'تعذر تحديث كلمة المرور');
      }
      if (!isAcceptablePassword(newPassword)) {
        throw new HttpsError(
          'invalid-argument',
          'كلمة المرور يجب ألا تقل عن 8 أحرف وأن تحتوي على حروف وأرقام بدون مسافات'
        );
      }

      const db = admin.firestore();
      const callerSnap = await db.collection('users').doc(request.auth.uid).get();
      if (!callerSnap.exists) {
        throw new HttpsError('permission-denied', 'غير مصرح بهذا الإجراء');
      }

      const caller = callerSnap.data() || {};
      if (caller.disabled === true || caller.role !== 'superadmin') {
        throw new HttpsError('permission-denied', 'غير مصرح بهذا الإجراء');
      }

      const targetSnap = await db.collection('users').doc(targetUid).get();
      if (!targetSnap.exists) {
        throw new HttpsError('not-found', 'المستخدم غير موجود');
      }

      const target = targetSnap.data() || {};

      try {
        await admin.auth().updateUser(targetUid, {password: newPassword});
      } catch (e) {
        logger.error('resetUserPassword updateUser failed', {
          code: e && e.code,
          message: e && e.message,
          targetUid
        });
        if (e && e.code === 'auth/user-not-found') {
          throw new HttpsError('not-found', 'حساب الدخول غير موجود في Firebase Auth');
        }
        if (e && e.code === 'auth/invalid-password') {
          throw new HttpsError('invalid-argument', 'كلمة المرور غير مقبولة');
        }
        throw new HttpsError('failed-precondition', 'تعذر تحديث كلمة المرور في Firebase Auth');
      }

      try {
        await db.collection('audit').add({
          action: 'user_password_changed',
          details: {
            uid: targetUid,
            name: target.name || null,
            role: target.role || null
          },
          uid: request.auth.uid,
          userName: caller.name || null,
          role: caller.role,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
      } catch (auditErr) {
        logger.warn('resetUserPassword audit write failed', {
          message: auditErr && auditErr.message
        });
      }

      return {ok: true};
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error('resetUserPassword unexpected error', {
        message: e && e.message,
        code: e && e.code
      });
      throw new HttpsError('internal', 'خطأ غير متوقع أثناء تغيير كلمة المرور');
    }
  }
);
