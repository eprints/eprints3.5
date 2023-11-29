class EPrints {
	_currentRepository = undefined

	constructor(params) {
		this._currentRepository = new EPrintsRepository();
	}

	currentRepository = () => this._currentRepository
}

class EPrintsRepository {
        /*
         * Retrieve one or more phrases from the server
         * @input associative array where the keys are phrase ids and the values
         * are pins
         * @f function to call with the resulting phrases
         * @textonly retrieve phrase text content only (defaults to false)
         */
	phrase(phrases, f, textonly) {
		var url = eprints_http_cgiroot + '/ajax/phrase?';
		if (textonly) url += 'textonly=1';
		new Ajax.Request(
			url, 
			{
                        	method: 'post',
                        	onException: (req, e) => {
                                	alert (e.toString());
                        	},
                        	onFailure: (transport) => {
                                	throw new Error ('Error ' + transport.status + ' requesting phrases (check server log for details)');
                        	},
                        	onSuccess: (transport) => {
                                	if (!transport.responseJSON) throw new Error ('Failed to get JSON from phrases callback');
                                	f (transport.responseJSON);
                        	},
                        	postBody: Object.toJSON (phrases)
                	}
		);
	}

}

var eprints = new EPrints();
