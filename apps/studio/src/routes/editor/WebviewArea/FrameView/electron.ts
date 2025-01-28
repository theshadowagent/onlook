import type { IFrameView, TFrameViewAPI } from './types';

export class ElectronFrame implements IFrameView {
    private webview: Electron.WebviewTag;

    constructor(private config: IFrameView) {
        this.webview = document.createElement('webview') as Electron.WebviewTag;
        this.webview.id = config.id;
        this.webview.src = config.url;
    }

    get id() {
        return this.config.id;
    }
    get url() {
        return this.config.url;
    }
    get dimension() {
        return this.config.dimension;
    }
    get position() {
        return this.config.position;
    }

    api(): TFrameViewAPI {
        return {
            executeJavaScript: (code) => this.webview.executeJavaScript(code),
            reload: () => this.webview.reload(),
            goBack: () => this.webview.goBack(),
            goForward: () => this.webview.goForward(),
            canGoBack: () => this.webview.canGoBack(),
            canGoForward: () => this.webview.canGoForward(),
        };
    }
}
