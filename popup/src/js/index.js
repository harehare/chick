import Elm from '../elm/Popup.elm';
import {
    EventIndexing,
} from 'Common/constants'
import {
    indexingStatus,
    setIndexingStatus,
    getOption
} from 'Common/option'
import {
    openUrl,
    getSyncStorage
} from 'Common/chrome';

(async () => {
    const option = await getSyncStorage('option');
    const {
        tags
    } = getOption(option);

    tags.sort();

    const app = Elm.Popup.fullscreen({
        suspend: indexingStatus(),
        query: '',
        tags
    });

    app.ports.openSearchPage.subscribe((query) => {
        openUrl(`${chrome.extension.getURL("option/index.html")}?q=${query}`, true);
    });

    app.ports.suspend.subscribe(status => {
        setIndexingStatus(status);
        console.log('suspend', status);
    });

    ['https://fonts.googleapis.com/css?family=Open+Sans'].forEach(url => {
        const link = document.createElement('link');
        link.href = url;
        document.body.appendChild(link);
    });
})();
