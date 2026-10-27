import { contextBridge, ipcRenderer } from "electron";

const call = (channel: string, ...args: unknown[]) => ipcRenderer.invoke(channel, ...args);
const bridge = {
  state: () => call("morde:state"),
  login: (origin: string, name: string, password: string, key: string) => call("morde:login", origin, name, password, key),
  logout: () => call("morde:logout"),
  showWeb: () => call("morde:show-web"),
  showSync: () => call("morde:show-sync"),
  publicPage: (path: "register" | "download", origin?: string) => call("morde:public-page", path, origin),
  workspaces: () => call("morde:workspaces"),
  chooseDirectory: (id: string) => call("morde:choose-directory", id),
  sync: (id: string, mode: string) => call("morde:sync", id, mode),
  stopSync: () => call("morde:sync-stop"),
  discardSync: () => call("morde:sync-discard"),
  onState: (listener: (value: unknown) => void) => { const cb = (_event: Electron.IpcRendererEvent, value: unknown) => listener(value); ipcRenderer.on("morde:state", cb); return () => ipcRenderer.off("morde:state", cb); },
  onSync: (listener: (value: unknown) => void) => { const cb = (_event: Electron.IpcRendererEvent, value: unknown) => listener(value); ipcRenderer.on("morde:sync-state", cb); return () => ipcRenderer.off("morde:sync-state", cb); },
};

contextBridge.exposeInMainWorld("morde", bridge);
