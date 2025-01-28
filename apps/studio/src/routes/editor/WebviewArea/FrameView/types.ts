export interface IFrameView {
    id: string;
    url: string;
    dimension: {
        width: number;
        height: number;
    };
    position: {
        x: number;
        y: number;
    };
    api(): TFrameViewAPI;
}

export type TFrameViewAPI = {
    executeJavaScript(code: string): Promise<any>;
    reload(): void;
    goBack(): void;
    goForward(): void;
    canGoBack(): boolean;
    canGoForward(): boolean;
};
