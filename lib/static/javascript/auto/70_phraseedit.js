
const ep_decode_html_entities = ( str ) => {
	str = str.replace( /\&quot;/g, "\"" );
	str = str.replace( /\&squot;/g, "'" );
	str = str.replace( /\&lt;/g, "<" );
	str = str.replace( /\&gt;/g, ">" );
	str = str.replace( /\&amp;/g, "&" );
	return str;
}

const ep_phraseedit_addphrase = ( event, base_id, csrf_token='' ) => {
	if( base_id == '' )
	{
		alert( "No phrase ID specified" );
		return false;
	}	
	if( document.getElementById("ep_phraseedit_"+base_id) != null )
	{
		alert( "The phrase '"+base_id+"' already exists." );
		return false;
	}

	document.getElementById("ep_phraseedit_add").disabled = true;
	document.getElementById("ep_phraseedit_newid").disabled = true;
	
	new Ajax.Request(
		eprints_http_cgiroot+"/users/home",
		{
			method: "post",
			onFailure: () => { 
				document.getElementById("ep_phraseedit_add").disabled = false;
				document.getElementById("ep_phraseedit_newid").disabled = false;
				alert( "AJAX request failed..." );
			},
			onException: (req, e) => { 
				document.getElementById("ep_phraseedit_add").disabled = false;
				document.getElementById("ep_phraseedit_newid").disabled = false;
				alert( "AJAX Exception " + e.message );
			},
			onSuccess: (response) => { 
				var text = response.responseText;
				document.getElementById("ep_phraseedit_add").disabled = false;
				document.getElementById("ep_phraseedit_newid").disabled = false;
				if( text.length == 0 )
				{
					alert( "No response from server..." );
				}
				else
				{
					document.getElementById("ep_phraseedit_newid").value = "";
					document.querySelector("#ep_phraseedit_table tr:nth-child(1)").outerHTML += text
				}
			},
			parameters: { 
				screen: "Admin::Phrases", 
				phraseid: base_id, 
				phrase: document.getElementById('ep_phraseedit_newid').value,
				csrf_token: csrf_token
			} 
		} 
	);
	return false;
}

const ep_phraseedit_save = (base_id, phrase, csrf_token='') => {
	new Ajax.Request(
		eprints_http_cgiroot+"/users/home",
		{
			method: "post",
			onFailure: () => { 
				var form = document.getElementById('ep_phraseedit_'+base_id);
				ep_phraseedit_enableform(form);
				alert( "AJAX request failed..." );
			},
			onException: (req, e) => { 
				var form = document.getElementById('ep_phraseedit_'+base_id);
				ep_phraseedit_enableform(form);
				alert( "AJAX Exception " + e.message );
			},
			onSuccess: (response) => { 
				var text = response.responseText;
				if( text.length == 0 )
				{
					ep_phraseedit_enableform(form);
					alert( "No response from server..." );
				}
				else
				{
					var form = document.getElementById('ep_phraseedit_'+base_id);
					form.parentNode.parentNode.outerHTML = text
				}
			},
			parameters: { 
				screen: "Admin::Phrases", 
				phraseid: base_id, 
				phrase: phrase,
				csrf_token: csrf_token
			} 
		} 
	);
}

const ep_phraseedit_disableform = (form) => {
	for(var i = 0; i < form.childNodes.length; ++i)
	{
		var n = form.childNodes[i];
		n.disabled = true;
	}
}

const ep_phraseedit_enableform = (form) => {
	for(var i = 0; i < form.childNodes.length; ++i)
	{
		var n = form.childNodes[i];
		n.disabled = false;
	}
}

const ep_phraseedit_edit = (div, phrases, csrf_token='') => {
	var container = div.parentNode;
	container.removeChild( div );

	/* less "ep_phraseedit_" */
	var base_id = div.id.replace( 'ep_phraseedit_', '' );

	var form = document.createElement( "form" );
	form.setAttribute( 'id', div.id );
	form._base_id = base_id;
	form._original = ep_decode_html_entities( div.innerHTML );
	form._widget = div;
	var textarea = document.createElement( 'textarea' );
	textarea.value = form._original;
	textarea.setAttribute( 'rows', '2' );
	textarea.setAttribute( 'aria-labelledby', div.id + "_label" );
	form.appendChild( textarea );

	var input;
	/* CSRF tokem */
	if ( csrf_token !== '' )
	{
		input = document.createElement( 'input' );
	        input.setAttribute( 'type', 'hidden' );
        	input.value = csrf_token;
		form.appendChild( input );
	}

	/* save */
	input = document.createElement( 'input' );
	input.setAttribute( 'type', 'button' );
	input.value = phrases['save'];
	input.addEventListener( 'click', (event) => {
		var form = event.element().parentNode;
		ep_phraseedit_disableform(form);
		var textarea = form.firstChild;
		ep_phraseedit_save(form._base_id, textarea.value, csrf_token);
	});
	form.appendChild( input );
	/* reset */
	input = document.createElement( 'input' );
	input.setAttribute( 'type', 'button' );
	input.value = phrases['reset'];
	input.addEventListener( 'click', (event) => {
		var form = event.element().parentNode;
		var textarea = form.firstChild;
		textarea.value = form._original;
	});
	form.appendChild( input );
	/* cancel */
	input = document.createElement( 'input' );
	input.setAttribute( 'type', 'button' );
	input.value = phrases['cancel'];
	input.addEventListener( 'click', (event) => {
		console.log(event)
		var form = event.element().parentNode;
		var container = form.parentNode;
		container.removeChild( form );
		container.appendChild( form._widget );
	});
	form.appendChild( input );

	container.appendChild( form );
	textarea.focus();
	while(textarea.scrollHeight > textarea.clientHeight && !window.opera)
	{
		textarea.rows += 1;
	}
}
