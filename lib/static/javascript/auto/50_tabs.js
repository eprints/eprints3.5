const ep_showTab = ( baseid, tabid, expensive ) => {
	let panels = document.getElementById(baseid + "_panels");
	panels.childNodes.forEach(e => e.style.display = "none")

	let tabs = document.getElementById(baseid + "_tabs");
	tabs.childNodes.forEach(e => e.classList.remove('ep_tab_selected'))

	let panel = document.getElementById(baseid+"_panel_"+tabid);
	panel.style.display = "block";

	let tab = document.getElementById(baseid+"_tab_"+tabid);
	tab.classList.add( "ep_tab_selected" );
	let anchors = tab.querySelectorAll( 'a' );
	anchors.forEach(a => a.blur())

	if(expensive && !panel.loaded)
	{
		var link = tab.querySelector('a');
		link = link.href.split('?');
		xhrRequest(link[0], {
			onSuccess: (response) => {
				let range = document.createRange();
				range.setStart(panel, 0);
				panel.replaceChildren(range.createContextualFragment(response.responseText));
				panel.loaded = 1;
			},
			method: "get",
			parametersString: 'ajax=1&' + link[1]
		});
	}

	return false;
};

