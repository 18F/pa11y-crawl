var pkg = require('./package.json');

var usage = function () {
	console.log('  '+pkg.name+' v'+pkg.version);
	console.log('  '+pkg.description);
	console.log();
	console.log('  Usage: pa11y-crawl [options] <url>');
	console.log();
	console.log('    -h, --help                  show this help message and exit');
	console.log('    -v, --version               show the version and exit');
	console.log('    -u, --url                   the URL to scan');
	console.log('    -s, --standard <name>       the accessibility standard to use: Section508, WCAG2A, WCAG2AA (default), WCAG2AAA');
	console.log('    -t, --timeout <ms>          the timeout in milliseconds');
	console.log('    -o, --output <file>         the location to write a JSON report');
	console.log('    -p, --parallel              run pa11y tests in parallel (heavy usage, can cause timeouts more easily)');
	console.log('    -x, --exclude               exclude likely assets in crawl (may speed crawling)');
	console.log('    -r, --reporter <reporter>   the reporter to use: json (default), ci');
	console.log('    -q, --quiet                 quiet mode: run tests with no output to stdout');
	console.log();
};

module.exports = usage;
