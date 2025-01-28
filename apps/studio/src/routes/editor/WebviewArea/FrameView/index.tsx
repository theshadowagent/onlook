import { useEffect, useRef } from 'react';
import { ElectronFrame } from './electron';
import { BrowserFrame } from './browser';
import type { IFrameView } from './types';

export const FrameView = ({
    settings,
    isElectron = true,
}: {
    settings: IFrameView;
    isElectron?: boolean;
}) => {
    const frameRef = useRef<IFrameView | null>(null);

    useEffect(() => {
        frameRef.current = isElectron ? new ElectronFrame(settings) : new BrowserFrame(settings);

        return () => {
            // Cleanup
        };
    }, [settings.id]);

    return (
        <div className="frame-container">
            {isElectron ? (
                <webview
                    id={settings.id}
                    src={settings.url}
                    style={{
                        width: settings.dimension.width,
                        height: settings.dimension.height,
                    }}
                />
            ) : (
                <iframe
                    id={settings.id}
                    src={settings.url}
                    style={{
                        width: settings.dimension.width,
                        height: settings.dimension.height,
                    }}
                    sandbox="allow-same-origin allow-scripts"
                />
            )}
        </div>
    );
};
