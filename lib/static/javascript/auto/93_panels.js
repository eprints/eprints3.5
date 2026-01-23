function ep_panel_init( active_panel_name, config, id )
{
  var active_id = "ep_panel_" + id + "__" + active_panel_name;

  if( config == "as_tiles" )
  {
     ep_open_panel_all(id);
     document.getElementById( id + "_buttons" ).style.display = "none";
     document.getElementById( id + "_controls" ).style.display = "none";
  }
  else // as_tabs
  {
    // this will do a 'deep' match, is this what we want?
    var content = document.getElementById(id).getElementsByClassName( "ep_panel_content" );
    for (var i = 0; i < content.length; i++)
    {
      var cid = content[i].id;
      if( cid && cid.startsWith("ep_panel_" + id ) && cid != active_id )
      {
        content[i].className += " ep_panel_hide";
      }
    }
    document.getElementById( id + "_links_" + active_panel_name ).className += " active";
    ep_close_panel_all_aux(id);
  }

  ep_toggle_b_panel_aux( id); // toggle to 'a'
}

function ep_open_panel(evt, id, panel_name)
{
  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  for (var i = 0; i < links.length; i++)
  {
    links[i].className = links[i].className.replace(" active", "");

    var content_id = "ep_panel_" + links[i].id.replace("_links_", "__" );
    var content = document.getElementById(content_id);
    content.className = content.className.replace(/ ep_open_panel_all/g, "");
    if( content.className.indexOf(" ep_panel_hide") == -1 ) { content.className += " ep_panel_hide"; }
  }

  var active_id = "ep_panel_" + id + "__" + panel_name;
  document.getElementById( active_id ).className = document.getElementById( active_id ).className.replace(" ep_panel_hide", "");
  document.getElementById(id + "_links_" + panel_name).className += " active";

  ep_close_panel_all_aux(id);
}

// if any panels have a ep_panel_onchange attribute set, assume its a javascript function and call it
function ep_update_panels( id )
{
  var panels = document.getElementById(id).getElementsByClassName("ep_panels");
  var arr = panels[0].getElementsByClassName("ep_panel_wrapper");
  for (var i = 0; i < arr.length; i++)
  {
    var ep_panel_onchange = arr[i].getAttribute( "ep_panel_onchange" );
    if( ep_panel_onchange )
    {
      window[ ep_panel_onchange ]();
    }
  }
}

// tell all the panels to resize when the window does
function ep_panel_window_resize()
{
  var sets = document.getElementsByClassName("ep_panel_container");
  for (var i = 0; i < sets.length; i++ )
  {
    ep_update_panels( sets[i].id );
  }
}
window.addEventListener('resize', ep_panel_window_resize);

function ep_open_panel_all(id)
{
  var panels = document.getElementById(id).getElementsByClassName("ep_panels"); ///too general
  panels[0].className += " ep_panels_all_opened";
  panels[0].className = panels[0].className.replace(/ ep_panels_all_closed/, "");

  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  for (var i = 0; i < links.length; i++)
  {
    links[i].className = links[i].className.replace(" active", "");

    // base content name on link name (as content itself contains more panels and therefore further content and we match too many, links is a simple list)
    var content_id = "ep_panel_" + links[i].id.replace("_links_", "__" );
    var content = document.getElementById(content_id);
    content.className += " ep_open_panel_all";
    content.className = content.className.replace(/ ep_panel_hide/g, "");

    var title_id = links[i].id.replace("_links_", "__" ) + "_title";
    var title = document.getElementById(title_id);
    title.style.display = "block";
  }

  document.getElementById( id + "_controls_open" ).style.display = "none";
//  document.getElementById( id + "_controls_close" ).style.display = "block";
  document.getElementById( id + "_controls_close" ).style.display = "inline-block";
  ep_panels_enable_link(id);

  // hide the first/prev/next/last controls
  var nav = document.getElementById(id).getElementsByClassName("ep_panel_nav");
  for (var i = 0; i < nav.length; i++)
  {
    nav[i].style.display = "none";
  }

  // hide the main nav
  var buttons = document.querySelector("#"+id+"_buttons")
  if( buttons )
  {
	buttons.style.display = "none";
  }

  ep_update_panels( id );
}

function ep_panels_disable_link(id)
{
  var toggle_a = document.getElementById( id + "_controls_toggle_a" );
  toggle_a?.style.setProperty("opacity", "0.0");
  toggle_a?.style.setProperty("cursor", "default");
  toggle_a?.style.setProperty("pointerEvents", "none");

  var toggle_b = document.getElementById( id + "_controls_toggle_b" );
  toggle_b?.style.setProperty("opacity", "0.0");
  toggle_b?.style.setProperty("cursor", "default");
  toggle_b?.style.setProperty("pointerEvents", "none");
}

function ep_panels_enable_link(id)
{
  var toggle_a = document.getElementById( id + "_controls_toggle_a" );
  toggle_a?.style.setProperty("opacity", "1.0");
  toggle_a?.style.setProperty("cursor", "initial");
  toggle_a?.style.setProperty("pointerEvents", "initial");
  
  var toggle_b = document.getElementById( id + "_controls_toggle_b" );
  toggle_b?.style.setProperty("opacity", "1.0");
  toggle_b?.style.setProperty("cursor", "initial");
  toggle_b?.style.setProperty("pointerEvents", "initial");
}

function ep_toggle_a_panel(id)
{
  ep_toggle_a_panel_aux(id)
  ep_toggle_a_panel_action(id);
  ep_update_panels(id);
}
function ep_toggle_a_panel_aux(id)
{
  document.getElementById( id + "_controls_toggle_a" )?.style.setProperty("display", "none");
  document.getElementById( id + "_controls_toggle_b" )?.style.setProperty("display", "inline-block");
}
function ep_toggle_a_panel_action(id) // easier to override
{
  var panels = document.getElementById(id).getElementsByClassName("ep_panels ep_panels_all_opened");
  panels[0].style.columns = 1;
}
function ep_toggle_b_panel(id)
{
  ep_toggle_b_panel_aux(id)
  ep_toggle_b_panel_action(id)
  ep_update_panels(id);
}
function ep_toggle_b_panel_aux(id)
{
  document.getElementById( id + "_controls_toggle_a" )?.style.setProperty("display", "inline-block");
  document.getElementById( id + "_controls_toggle_b" )?.style.setProperty("display", "none");
}
function ep_toggle_b_panel_action(id) // easier to override
{
  var panels = document.getElementById(id).getElementsByClassName("ep_panels ep_panels_all_opened");
  panels[0].style.columns = 2;
}

function ep_close_panel_all(id)
{
  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  for (var i = 0; i < links.length; i++)
  {
    links[i].className = links[i].className.replace(" active", "");

    var content_id = "ep_panel_" + links[i].id.replace("_links_", "__" );
    var content = document.getElementById(content_id);
    content.className = content.className.replace(/ ep_open_panel_all/g, "");
    if( content.className.indexOf(" ep_panel_hide") == -1 ) { content.className += " ep_panel_hide"; }
    if(i==0){ content.className = content.className.replace(/ ep_panel_hide/g, ""); } // default to first panel
  }
  links[0].className += " active";

  var buttons = document.querySelector("#"+id+"_buttons")
  if( buttons )
  {
        buttons.style.display = "inline-block";
  }

  ep_close_panel_all_aux(id);
}

function ep_close_panel_all_aux(id)
{
  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  for (var i = 0; i < links.length; i++)
  {
    var title_id = links[i].id.replace("_links_", "__" ) + "_title";
    var title = document.getElementById(title_id);
    title.style.display = "none";
  }

//  document.getElementById( id + "_controls_open" ).style.display = "block";
  document.getElementById( id + "_controls_open" ).style.display = "inline-block";
  document.getElementById( id + "_controls_close" ).style.display = "none";
  ep_panels_disable_link(id);

  var panels = document.getElementById(id).getElementsByClassName("ep_panels"); ///too general
  panels[0].className = panels[0].className.replace(/ ep_panels_all_opened/, " ep_panels_all_closed");

  // show the first/prev/next/last controls
  var nav = document.getElementById(id).getElementsByClassName("ep_panel_nav");
  for (var i = 0; i < nav.length; i++)
  {
    nav[i].style.display = "inline-block";
  }

  ep_update_panels( id );
}

function ep_open_prev_panel(evt, id, loop)
{
  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  for (var i = 1; i < links.length; i++) // not first panel
  {
    if( links[i].className.indexOf(" active") > 0 )
    {
      ep_open_panel_number(evt, id, i); // panel names are 1 based indexes are 0 based
      return;
    }
  }

  if( loop == 1 )
  {
    ep_open_panel_number(evt, id, links.length);
  }
}

function ep_open_next_panel(evt, id, loop)
{
  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  for (var i = 0; i < links.length-1; i++) // not last panel
  {
    if( links[i].className.indexOf(" active") > 0 )
    {
      if( loop == 1 && (i+1) >= links.length ) { i = 0; }
      ep_open_panel_number(evt, id, i+2);
      return;
    }
  }

  if( loop == 1 )
  {
    ep_open_panel_number(evt, id, 1);
  }
}

function ep_open_panel_number(evt, id, index)
{
  var links = document.getElementById(id).getElementsByClassName(id + "_links");
  if( links.length < index ) { console.log("invalid index"); return; }
  var panel_name  = links[index-1].id.replace(id + "_links_", "");
  ep_open_panel(evt, id, panel_name);
}
