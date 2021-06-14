
const {Collection} = require('./collection');

class DetailsCollection extends Collection {

    constructor(item) {
        super(item);
        this.type = item.data.toObject().type;
    }
    
    async fetch(url) {
        let pageUrl = new PageURL(url);
        let doc = await super.fetch(url);

        let info_data = this.info_data;
        info_data.summary = doc.querySelector('.roms-desc').text.trim();
        let img = doc.querySelector('.rom-cover').attr('src');
        info_data.data = {
            type: this.type,
            images: [img],
            cover: img
        };

        let items = [];
        let item = glib.DataItem.new();
        item.title = 'Download';
        let downloadUrl = pageUrl.href(doc.querySelector('.dlbtn-cntr > a').attr('href'));
        item.link = await this.download({
            url: downloadUrl
        });
        items.push(item);

        return items;
    }

    reload(_, cb) {
        this.fetch(this.url).then((results)=>{
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            console.log(err.message + "\n" + err.stack);
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }

    async download(data) {
        let doc = await super.fetch(data.url);
        return doc.querySelector('.wait__link').attr('href');
    }
}

module.exports = function(item) {
    return DetailsCollection.new(item);
};