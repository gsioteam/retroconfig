
const {Collection} = require('./collection');

const typeDB = {
    'amiga-500': 'Commodore - Amiga',
    'amstrad-cpc': 'Amstrad - CPC',
    'atari-2600': 'Atari - 2600',
    'atari-5200': 'Atari - 5200',
    'atari-7800': 'Atari - 7800',
    'atari-800': 'Atari - 5200',
    'atari-jaguar': 'Atari - Jaguar',
    'atari-lynx': 'Atari - Lynx',
    'atari-st': 'Atari - ST',
    'capcom-play-system-1': 'FBNeo - Arcade Games',
    'capcom-play-system-2': 'FBNeo - Arcade Games',
    'casio-loopy': 'Casio - Loopy',
    'casio-pv1000': 'Casio - PV-1000',
    'colecovision': 'Coleco - ColecoVision',
    'colecovision-adam': 'Coleco - ColecoVision',
    'commodore-64': 'Commodore - 64',
    'commodore-max-machine': 'Commodore - 64',
    'commodore-pet': 'Commodore - Amiga',
    'commodore-plus4-c16': 'Commodore - Plus-4',
    'commodore-vic20': 'Commodore - VIC-20',
    'emerson-arcadia-2001': 'Emerson - Arcadia 2001',
    'entex-adventure-vision': 'Entex - Adventure Vision',
    'epoch-super-cassette-vision': 'Epoch - Super Cassette Vision',
    'fairchild-channel-f': 'Fairchild - Channel F',
    'funtech-super-acan': 'Funtech - Super Acan',
    'game-gear': 'Sega - Game Gear',
    'gameboy': 'Nintendo - Game Boy',
    'gameboy-advance': 'Nintendo - Game Boy Advance',
    'gameboy-color': 'Nintendo - Game Boy Color',
    'gamecube': 'Nintendo - GameCube',
    'gamepark-gp32': 'GamePark - GP32',
    'gce-vectrex': 'GCE - Vectrex',
    'hartung-game-master': 'Hartung - Game Master',
    'intellivision': 'Mattel - Intellivision',
    'magnavox-odyssey-2': 'Magnavox - Odyssey2',
    'mame-037b11': 'MAME',
    'msx-2': 'Microsoft - MSX2',
    'msx-computer': 'Microsoft - MSX',
    'neo-geo': 'FBNeo - Arcade Games',
    'neo-geo-pocket': 'SNK - Neo Geo Pocket',
    'neo-geo-pocket-color': 'SNK - Neo Geo Pocket Color',
    'nintendo': 'Nintendo - Nintendo Entertainment System',
    'nintendo-64': 'Nintendo - Nintendo 64',
    'nintendo-ds': 'Nintendo - Nintendo DS',
    'nintendo-famicom-disk-system': 'Nintendo - Family Computer Disk System',
    'nintendo-pokemon-mini': 'Nintendo - Pokemon Mini',
    'nintendo-virtual-boy': 'Nintendo - Virtual Boy',
    'nintendo-wii': 'Nintendo - Wii',
    'philips-videopac': 'Philips - Videopac+',
    'playstation': 'Sony - PlayStation',
    'playstation-2': 'Sony - PlayStation 2',
    'playstation-portable': 'Sony - PlayStation Portable',
    'rca-studio-ii': 'RCA - Studio II',
    'sega-32x': 'Sega - 32X',
    'dreamcast': 'Sega - Dreamcast',
    'sega-genesis': 'Sega - Mega Drive - Genesis',
    'sega-master-system': 'Sega - Master System - Mark III',
    'sega-pico': 'Sega - PICO',
    'sega-sg1000': 'Sega - SG-1000',
    'sharp-x68000': 'Sharp - X68000',
    'sinclair-zx81': 'Sinclair - ZX 81',
    'sufami-turbo': 'Nintendo - Sufami Turbo',
    'super-nintendo': 'Nintendo - Super Nintendo Entertainment System',
    'thomson-mo5': 'Thomson - MOTO',
    'tiger-game-com': 'Tiger - Game.com',
    'turbografx-16': 'NEC - PC Engine - TurboGrafx 16',
    'vtech-creativision': 'VTech - CreatiVision',
    'vtech-v-smile': 'VTech - V.Smile',
    'watara-supervision': 'Watara - Supervision',
    'wonderswan': 'Bandai - WonderSwan',
    'zx-spectrum': 'Sinclair - ZX Spectrum',
};

class DetailsCollection extends Collection {
    
    getType() {
        let url = new URL(this.url);
        let segs = url.pathname.split('/');
        if (segs[1] === 'roms') {
            return typeDB[segs[2]];
        }
    }

    async fetch(url) {
        let pageUrl = new PageURL(url);
        let doc = await super.fetch(url);

        let info_data = this.info_data;
        let cover = pageUrl.href(doc.querySelector('[itemprop="image"]').attr('src'));
        info_data.data = {
            type: this.getType(),
            images: [cover],
            cover: cover
        };

        let table = doc.querySelector('table.table');
        let trs = table.querySelectorAll('tr');
        info_data.title = trs[0].querySelectorAll('td')[1].text;
        let node = doc.querySelector('.container > .row > div:first-child h2');
        console.log('test ' + node.text);
        info_data.summary = doc.querySelector('.container > .row > div:first-child h2+div').text;
        let uri = new URL(url);
        let romUrl = pageUrl.href(`/download/${uri.pathname}`);

        let items = [];
        doc = await super.fetch(romUrl);
        let downloadLink = doc.querySelector('.installetize').attr('href');
        let item = glib.DataItem.new();
        item.title = 'Download';
        item.link = downloadLink;
        item.data = {
            type: 'direct'
        };
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
}

module.exports = function(item) {
    return DetailsCollection.new(item);
};