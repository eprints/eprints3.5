class Screen_BatchEdit {
	constructor(prefix) {
		this.prefix = prefix;

		document.getElementById(this.prefix + '_action_add_change').addEventListener('click', (e) => {
			this.action_add_change(e)
		});

		document.getElementById(this.prefix + '_action_edit').addEventListener('click', (e) => {
			this.action_edit(e)
                });

		document.getElementById(this.prefix + '_action_remove').addEventListener('click', (e) => {
			this.action_remove(e)
                });

		document.getElementById(this.prefix + '_iframe').addEventListener('load', (e) => {
			this.finished(e)
                });

		this.refresh();
	}

        refresh() {
                var container = document.getElementById(this.prefix + '_sample');
                if( !container )
                        return;

                container.innerHTML = '<img src="' + eprints_http_root + '/style/images/lightbox/loading.gif" />';

                var ajax_parameters = {};
                ajax_parameters['screen'] = document.querySelector('#'+this.prefix+"_form"+' [id="screen"]').getAttribute("value");
                ajax_parameters['cache'] = document.querySelector('#'+this.prefix+"_form"+' [id="cache"]').getAttribute("value");
                ajax_parameters['ajax'] = 1;
                ajax_parameters['_action_list'] = 1;

                new Ajax.Updater(
                        container,
                        eprints_http_cgiroot+'/users/home',
                        {
                                method: "get",
                                parameters: ajax_parameters
                        }
                );
        }

        begin() {
                var container = document.getElementById(this.prefix + '_progress');
                var uuid = document.querySelector('#'+this.prefix+"_form"+' [id="progressid"]').getAttribute("value");

                document.getElementById(this.prefix + '_form').style.display = "none";

                if (container.pe)
                        container.pe.stop();

                var progress = new EPrintsProgressBar({bar: 'progress_bar_orange.png'}, container);

                container.pe = new PeriodicalExecuter(function(pe) {
                        var url = eprints_http_cgiroot + '/users/ajax/upload_progress?progressid='+uuid;
                        new Ajax.Request(url, {
                                method: 'get',
                                onSuccess: function(transport) {
                                        var json = transport.responseJSON;
                                        if( !json ) {
                                                pe.stop();
                                                return;
                                        }
                                        var percent = json.received / json.size;
                                        progress.update( percent, Math.round(percent*100)+'%' );
                                }
                        });
                }, .2);
        }

        finished(evt) {
                var iframe = document.getElementById(this.prefix + '_iframe');
                var container = document.getElementById(this.prefix + '_progress');
                container.pe.stop();
                container.innerHTML = iframe.contentWindow.document.body.innerHTML;

                document.getElementById(this.prefix + '_changes').innerHTML = '';
                document.getElementById(this.prefix + '_form').style.display = '';

                this.refresh();
        }

        action_add_change(evt) {
                var ajax_parameters = {};
                ajax_parameters['screen'] = document.querySelector('#'+this.prefix+"_form"+' [id="screen"]').getAttribute("value");
                ajax_parameters['cache'] = document.querySelector('#'+this.prefix+"_form"+' [id="cache"]').getAttribute("value");
                ajax_parameters['ajax'] = 1;
                ajax_parameters['_action_add_change'] = 1;
                ajax_parameters['field_name'] = document.querySelector('#'+this.prefix+"_form"+' [id='+this.prefix+'_field_name]').value;

		new Ajax.Updater(this.prefix + '_changes', eprints_http_cgiroot+"/users/home",
                        {
                                method: "get",
                                onFailure: function(transport) {
                                        throw new Error ("Error in AJAX request: " + transport.responseText);
                                },
                                onException: function(transport, e) {
                                        throw e;
                                },
                                parameters: ajax_parameters,
                                insertion: Insertion.Bottom
                        }
                );

		evt.preventDefault();
		evt.stopPropagation();
        }

        action_edit(evt) {
                this.begin();
        }

        action_remove(evt) {
		let message = evt.target.getAttribute ('_phrase');

                if( confirm( message ) != true )
                {
			evt.preventDefault();
			evt.stopPropagation();
                        return false;
                }

                this.begin();
        }

}
