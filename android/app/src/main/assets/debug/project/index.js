
const {Collection} = require('./collection');

function makeItem(node, pageUrl, type) {
    let item = glib.DataItem.new();
    let link = node.querySelector('a');
    item.title = node.querySelector('span').text;
    let url = link.attr('href');
    item.link = pageUrl.href(url);
    item.picture = pageUrl.href(node.querySelector('img').attr('src'));
    item.data = {
        type: type
    };

    return item;
}

class CategoryCollection extends Collection {

    constructor(data) {
        super(data);
        this.page = 0;
        this.type = data.id;
    }

    async fetch(url) {
        let pageUrl = new PageURL(url);

        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('.related-holder > .form-box');

        let items = [];
        for (let node of nodes) {
            items.push(makeItem(node, pageUrl, this.type));
        }
        return items;
    }

    makeURL(page) {
        if (this.url.indexOf('{0}') == -1) return this.url;
        return this.url.replace('{0}', page + 1);
    }

    reload(_, cb) {
        let page = 0;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }

    loadMore(cb) {
        if (this.url.indexOf('{0}') == -1) return false;
        let page = this.page + 1;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.appendData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(info) {
    return CategoryCollection.new(info.toObject());
};
