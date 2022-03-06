# Follow the snow

This is the app that builds the static site for Follow the Snow.
It goes through a list of ski resorts and locations to get the snow report (inches fallen).

## Usage

Building the site will take awhile.
The NOAA API is used to get information about current and upcoming snow conditions.
They rate limit pretty heavily, so a `sleep` is put in between every API call.

This will manually build the site.

```bash
bundle install
rake build
```

Then commit the changed pages, which will be deployed as a static site via Github Pages and Cloudflare.

The page is build every morning from 4-8am MST, so that latest snow totals for the day are available.
This is using [Github Actions](https://github.com/jtarchie/followthesnow/blob/main/.github/workflows/build.yml) to do so.

### Test

Everything is tested because it should be.

```bash
bundle install
bundle exec rspec
```

## Sources

Theses are the resources to populate the resorts.
The meta information is captured in the `resorts.csv`.
This can most likely be automated to scrape, however, it is just copy and paste for now.

- California: https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_California
- Colorado: https://en.wikipedia.org/wiki/List_of_Colorado_ski_resorts
- Idaho: https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Idaho
- Montana: https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Montana
- New Mexico: https://en.wikipedia.org/wiki/List_of_New_Mexico_ski_resorts
- Utah: https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Utah
- Wyoming: https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Wyoming
