
const {Collection} = require('./collection');

const typeDB = {
    'gameboy-advance': 'Nintendo - Game Boy Advance',
    'super-nintendo': 'Nintendo - Super Nintendo Entertainment System',
    'nintendo-ds': 'Nintendo - Nintendo DS',
    'nintendo-64': 'Nintendo - Nintendo 64',
    'playstation-portable': 'Sony - PlayStation Portable',
    'gameboy-color': 'Nintendo - Game Boy Color',
    'nintendo': 'Nintendo - Nintendo Entertainment System',
    'playstation': 'Sony - PlayStation',
    'gamecube': 'Nintendo - GameCube',
    'nintendo-wii': 'Nintendo - Wii',
    'gameboy': 'Nintendo - Game Boy',
    'sega-genesis': 'Sega - Mega Drive - Genesis',
    'playstation-2': 'Sony - PlayStation 2',
    'mame-037b11': 'MAME',
    'amiga-500': 'Commodore - Amiga',
    'neo-geo': 'SNK - Neo Geo CD'
};

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
        this.page = 0;
    }

    async fetch(url) {
        let pageUrl = new PageURL(url);
        let text = await super.fetch(url, true);
        let result = JSON.parse(text);
        
        let results = [];
        for (let data of result) {
            let item = glib.DataItem.new();

            item.link = pageUrl.href(`/${data.romSlug}-${data.consoleSlug}-rom`);
            item.title = data.name.replace('&amp;', '&');
            let type = typeDB[data.consoleSlug];
            item.subtitle = type;
            item.data = {
                type: type
            };
            results.push(item);
        }
        return results;
    }

    makeURL(page) {
        return this.url.replace('{0}', glib.Encoder.urlEncode(this.key));
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        let page = data.get("page") || 0;
        if (!this.key) return false;
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

}

module.exports = function(data) {
    return SearchCollection.new(data ? data.toObject() : {});
};