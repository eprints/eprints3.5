window.onload = () => {
	document.querySelectorAll(".js_admin_storagemanager_show_stats").forEach((div) => {
		js_admin_storagemanager_load_stats(div);
	})
};

const js_admin_storagemanager_load_stats = (div) => {
	var pluginid = div.id.substring(6);

	xhrRequest(
		eprints_http_cgiroot+"/users/home",
		{
			method: "get",
			onFailure: () => { 
				alert( "AJAX request failed..." );
			},
			onException: (response) => { 
				alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
			},
			onSuccess: (response) => { 
				var text = response.responseText;
				if( text.length == 0 )
				{
					alert( "No response from server..." );
				}
				else
				{
					div.innerHTML = text;
				}
			},
			parametersString: { 
				ajax: "stats",
				screen: "Admin::StorageManager", 
				store: pluginid,
				csrf_token: getHeaderVariable( "csrf_token" )
			},
		} 
	);
}

const js_admin_storagemanager_migrate = (button) => {
	var form = button.parentNode;

	var ajax_parameters = serializeForm(form);
	ajax_parameters['ajax'] = 'migrate';

	form._original = form.innerHTML;
	form.innerHTML = document.getElementById('ep_busy_fragment').innerHTML

	xhrRequest(
		eprints_http_cgiroot+"/users/home",
		{
			method: "post",
			onFailure: () => { 
				alert( "AJAX request failed..." );
				form.innerHTML = form._original;
			},
			onException: (response) => { 
				alert( "AJAX Exception: Status " + response.status + " " + response.statusText );
			},
			onSuccess: (response) => {
				var text = response.responseText;
				if( text.length == 0 )
				{
					alert( "No response from server..." );
				}
				else
				{
					div = document.getElementById('stats_'+ajax_parameters['target']);
					if (!ajax_parameters['target'])
					{
						alert("Select target from dropdown");
					}
					else if ( !div )
					{
						alert("Can't find stats_"+ajax_parameters['target']);
					}
					else
					{
						div.innerHTML = div._original
						js_admin_storagemanager_load_stats(div);
					}
				}
				form.innerHTML = form._original;
			},
			parameters: ajax_parameters
		} 
	);

	return false;
}

const js_admin_storagemanager_delete = (button) => {
	var form = button.parentNode;

	var ajax_parameters = serializeForm(form);
	ajax_parameters['ajax'] = 'delete';

	form._original = form.innerHTML;
	form.innerHTML = document.getElementById('ep_busy_fragment').innerHTML;

	xhrRequest(
		eprints_http_cgiroot+"/users/home",
		{
			method: "post",
			onFailure: () => { 
				alert( "AJAX request failed..." );
				form.innerHTML = form._original;
			},
			onException: (req, e) => { 
				alert( "AJAX Exception " + e );
				form.innerHTML = form._original;
			},
			onSuccess: (response) => { 
				var text = response.responseText;
				if( text.length == 0 )
				{
					alert( "No response from server..." );
				}
				else
				{
					div = document.getElementById('stats_'+ajax_parameters['store']);
					if( !div )
					{
						alert("Can't find stats_"+ajax_parameters['target']);
					}
					else
					{
						div.innerHTML = div._original;
						js_admin_storagemanager_load_stats(div);
					}
				}
				form.innerHTML = form._original;
			},
			parameters: ajax_parameters
		} 
	);

	return false;
}


