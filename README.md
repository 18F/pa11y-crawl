# pa11y-crawl

For testing the accessibility of website, [`pa11y`](https://github.com/nature/pa11y) is a great tool. It only runs on one page at a time, though, so this tool crawls a site to find all HTML pages and runs `pa11y` on each one.

As a word of warning, this can be time and resource intensive, so make sure that both you and the site owner are cool with this before running.

## Installation

```bash
npm install -g pa11y-crawl
```

## Usage

### Basic usage

```bash
pa11y-crawl [URL]
```

### Advanced usage

```text
  Options:

    -h, --help                  show this help message and exit
    -v, --version               show the version and exit
    -u, --url                   the URL to scan
    -s, --standard <name>       the accessibility standard to use: Section508, WCAG2A, WCAG2AA (default), WCAG2AAA
    -t, --timeout <ms>          the timeout in milliseconds
    -o, --output <file>         the location to write a JSON report
    -p, --parallel              run pa11y tests in parallel (heavy usage, can cause timeouts more easily)
    -x, --exclude               exclude likely assets in crawl (may speed crawling)
    -r, --reporter <reporter>   the reporter to use: json (default), ci
    -q, --quiet                 quiet mode: run tests with no output to stdout
```

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
