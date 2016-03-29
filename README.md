# pa11y-crawl

For testing the accessibility of website, [`pa11y`](https://github.com/nature/pa11y) is a great tool. It only runs on one page at a time, though, so this tool crawls a site to find all HTML pages and runs `pa11y` on each one.

It is also designed to be used as the data collection tool for [continua11y](https://github.com/18f/continua11y), a continuous integration service for web accessibility.

## Installation

```bash
npm install -g pa11y-crawl
```

`jq` is also required in order to manipulate JSON files. See that project's [download instructions](https://stedolan.github.io/jq/download/) to install it.

## Usage

### Basic usage

```bash
pa11y-crawl [URL]
```

### Advanced usage

```text
Usage: pa11y-crawl [options] <URL>

Options:
  -c, --continua11y     set continua11y URL (default: continua11y.18f.gov)
  -d, --directory       use an existing local directory instead of wget
  -h, --help            show this help message and exit
  -i, --ci              continuous integration mode; incorporates repo metadata and sends a report to continua11y
  -m, --sitemap         use the site's sitemap.xml to find pages, rather than wget spider
  -o, --output          set output file for report (default: ./results.json)
  -q, --quiet           quiet mode
  -s, --standard        set accessibility standard (Section508, WCAG2A, WCAG2AA (default), WCAG2AAA)
  -t, --temp-dir        set location for storing temporary files (default: ./temp)
  -v, --version         show program version and exit
```

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
