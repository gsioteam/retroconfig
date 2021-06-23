
const {Collection} = require('./collection');
const makeItem = require('./make_item');

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
    }

    async fetch(key) {
        let pageUrl = new PageURL(this.url);
        let doc = await super.fetch(this.url, {
            method: 'POST',
            body: `romsearch=${glib.Encoder.urlEncode(key)}`,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });
        let nodes = doc.querySelectorAll('table.table tbody > tr');
        
        let results = [];
        for (let node of nodes) {
            results.push(makeItem(pageUrl, node));
        }
        return results;
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        if (!this.key) return false;
        this.fetch(this.key).then((results)=>{
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            console.log(err.message + '\n' + err.stack);
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    } 
}

module.exports = function(data) {
    return SearchCollection.new(data ? data.toObject() : {});
};