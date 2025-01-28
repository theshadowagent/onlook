import type { IFrameView, TFrameViewAPI } from './types';

export class BrowserFrame implements IFrameView {
    private iframe: HTMLIFrameElement;

    constructor(private config: IFrameView) {
        this.iframe = document.createElement('iframe');
        this.iframe.id = config.id;
        this.iframe.src = config.url;
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
            executeJavaScript: async (code) => {
                return new Promise((resolve) => {
                    const message = { type: 'executeJS', code };
                    this.iframe.contentWindow?.postMessage(message, '*');

                    const handler = (event: MessageEvent) => {
                        if (event.data.type === 'executeJSResult') {
                            window.removeEventListener('message', handler);
                            resolve(event.data.result);
                        }
                    };
                    window.addEventListener('message', handler);
                });
            },
            reload: () => this.iframe.contentWindow?.location.reload(),
            goBack: () => this.iframe.contentWindow?.history.back(),
            goForward: () => this.iframe.contentWindow?.history.forward(),
            canGoBack: () => (this.iframe.contentWindow?.history?.length ?? 0) > 1,
            canGoForward: () => false, // Not easily implementable in iframe
        };
    }
}
