'use strict';

/**
 * Redirects URLs to default document. Examples:
 *
 * /blog            -> /blog/index.html
 * /blog/july/      -> /blog/july/index.html
 * /blog/header.png -> /blog/header.png
 * https://stackoverflow.com/questions/31017105/how-do-you-set-a-default-root-object-for-subdirectories-for-a-statically-hosted
 */

let defaultDocument = 'index.html';

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;

    if (request.uri == "/feed.xml" || request.uri == "atom.xml") {

        //Generate HTTP redirect response to a different landing page.
        const redirectResponse = {
            status: '301',
            statusDescription: 'Moved Permanently',
            headers: {
                'location': [{
                    key: 'Location',
                    value: '/index.xml',
                }],
                'cache-control': [{
                    key: 'Cache-Control',
                    value: "max-age=3600"
                }],
            },
        };
        callback(null, redirectResponse);
    }
    if (request.uri != "/") {
        let paths = request.uri.split('/');
        let lastPath = paths[paths.length - 1];
        let isFile = lastPath.split('.').length > 1;

        if (!isFile) {
            if (lastPath != "") {
                request.uri += "/";
            }

            request.uri += defaultDocument;
        }

        console.log(request.uri);
    }

    callback(null, request);
};