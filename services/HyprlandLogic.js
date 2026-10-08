function titleFor(toplevel) {
	if (!toplevel) return "Unknown";
	if (toplevel.title?.length) return toplevel.title;
	if (toplevel.wayland?.appId?.length) return toplevel.wayland.appId;
	if (toplevel.lastIpcObject?.class?.length)
		return toplevel.lastIpcObject.class;
	return "Untitled";
}
