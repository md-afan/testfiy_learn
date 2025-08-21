import { getApp } from 'firebase-admin/app';
import { getAppCheck } from 'firebase-admin/app-check';
import { HttpsError } from 'firebase-functions/v2/https';

/**
 * Middleware to verify Firebase App Check token
 * @param {import('firebase-functions/v2').CallableRequest} context
 * @throws {HttpsError} If App Check verification fails
 */
export const verifyAppCheck = async (context) => {
    // Check if request includes App Check metadata
    if (!context.app) {
        throw new HttpsError(
            'failed-precondition',
            'The function must be called from an App Check verified app.',
            { code: 'MISSING_APP_CHECK' }
        );
    }

    try {
        // Verify the App Check token
        const appCheckToken = context.request.headers['x-firebase-appcheck'];
        if (!appCheckToken) {
            throw new HttpsError(
                'failed-precondition',
                'App Check token is missing',
                { code: 'MISSING_APP_CHECK_TOKEN' }
            );
        }

        await getAppCheck().verifyToken(appCheckToken);
    } catch (err) {
        throw new HttpsError(
            'failed-precondition',
            'Invalid App Check token',
            { 
                code: 'INVALID_APP_CHECK',
                details: err instanceof Error ? err.message : String(err)
            }
        );
    }
};

/**
 * Higher-order function to wrap callable functions with App Check verification
 * @param {Function} handler
 * @returns {import('firebase-functions/v2').HttpsFunction}
 */
export const withAppCheck = (handler) => {
    return (request, response) => {
        return verifyAppCheck(request)
            .then(() => handler(request, response))
            .catch(err => {
                if (err instanceof HttpsError) throw err;
                throw new HttpsError('internal', err.message);
            });
    };
};