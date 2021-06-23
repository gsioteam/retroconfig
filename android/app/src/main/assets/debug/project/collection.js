class Collection extends glib.Collection {

    constructor(data) {
        super(data);
        this.url = data.url || data.link;
    }

    /**
     * 
     * @param {string} url 
     * @param {Object} options 
     * @param {boolean} options.raw result is raw text or html document
     * @param {string} options.method request method
     * @param {string|*} options.body request body
     * @param {Object} options.headers request headers
     * @returns 
     */
    fetch(url, options) {
        options = options || {};
        let raw = options.raw;
        let method = options.method || 'GET';
        let body = options.body;
        let headers = options.headers;
        return new Promise((resolve, reject)=>{
            let req = glib.Request.new(method, url);
            // req.setHeader('User-Agent', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36');
            req.setHeader('Accept-Language', 'en-US,en;q=0.9');
            if (headers) {
                for (let key in headers) {
                    req.setHeader(key, headers[key]);
                }
            }
            if (body) {
                req.setBody(glib.Data.fromString(body));
            }
            this.callback = glib.Callback.fromFunction(() => {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (this.onResponse) {
                        this.onResponse(req);
                    }
                    if (body) {
                        if (raw)
                            resolve(body.text());
                        else
                            resolve(glib.GumboNode.parse(body));
                    } else {
                        reject(glib.Error.new(301, "Response null body"));
                    }
                }
            });
            req.setOnComplete(this.callback);
            req.start();
        });
    }
}

module.exports = {
    Collection
};