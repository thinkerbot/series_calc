# SeriesCalc

Calculates a series allowing the input variables to change over time, as well
as sampling of subparts of the series. Uses a caching strategy that allows for
lazy calculation, resulting in quick writes and quick reads after the
calculations have been cached.

## Development

Clone and setup the project:

    bundle install

Run the tests:

    ./test/suite
