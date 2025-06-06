// JSON grabbed from a textarea is not encoded correctly
// This tidies up some known issues
// -> backslash not being escaped leads to JSON.parse to think it is an escape character
// -> newlines chars are not valid JSON.parse and need to be \n
String.prototype.prepare_json_parse = function() {
	return this.replaceAll(/([^\\"])(\\)([^\\"])/g, "$1\\$3")
		.replaceAll('\n', '\\\\n')
		.replaceAll('\t', '\\\\t');
};
