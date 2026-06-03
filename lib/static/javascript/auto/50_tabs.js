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

// Sets the tabs_current value, to be picked up in XHTML.pm/tabs
window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll(".ep_tab_bar > li").forEach((tabButton) => {
        tabButton.addEventListener("click", () => {
            // Pull out the name of the tab row, and the tab ID of the button just clicked
            let tabRowName = tabButton.getAttribute("id").split("_").slice(0,-2).join("_");
            let currentTabID = tabButton.getAttribute("id").split("_").at(-1);

            // Put the ID of the current tab in the search params
            let searchParams = new URLSearchParams(window.location.search);
            searchParams.set(`${tabRowName}_current`, currentTabID)
            history.replaceState(window.title, window.title, window.location.href.split('?')[0] + '?' + searchParams.toString())
        })
    })
})