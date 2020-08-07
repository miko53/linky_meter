# linky_meter

script to retrieve data from linky meter (french electrical meter provided by enedis).

This version is now compatible of new API of enedis (*deployed from june 2020*).

By the way, to avoid the captcha login, it is necessary to log before on a classical browser (e.g Chrome, Firefox) and to retrieve the user cookies (internalAuthId).
With this method, a login/password is required for the authentification.

authentification data shall be provided by the environnement:
* LINKY_USERNAME => login
* LINKY_PASSWORD => password
* LINKY_COOKIE_INTERNAL_AUTH_ID => the value of the cookie 'internalAuthId'


