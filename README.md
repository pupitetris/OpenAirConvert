# OpenAirConvert
Yet another Open Air converter because I don't like the output of those available.

## OpenAir file format documentation:
http://www.winpilot.com/UsersGuide/UserAirspace.asp

This project was specificaly made for the Airspaces-MX project that documents
usable airspace for ultralight gliders in Mexico.

The initial intent is to create an OpenAir to KML converter, and go from there
as more formats are required.

Some extensions to the format have been implemented for a better description
of the data, since OpenAir is primarily a presentation format, not a semantic
format. The extensions are embeded in the file inside comments to allow for
backwards compatibility.

The software aims to be 100% usable for files without these extensions and any 
fixes or requests to make it parse difficult files are welcome.

File metadata extensions: 
  * FMT (File format)
  * VER (File version <YYYY-MM-DD>)
  * DESC: START, DESC: END (General file description),
  * AUTHOR (One per author <handle email name...>)
  * TODO (File notes <(handle) notes...>)
  * ISSUE (Bugs <(handle) issue...>)
  * LOG (<(handle) YYYY-MM-DD Changelog...>)

Element grouping metadata: 
  * DAT (Chart source issuing date)
  * POP (Closest Relevant Population <city, state>)
  * APT (Airport name <ICAO name>)
  * APT: END marks end of airport grouping.
  * NOTE (Notes for airport or polygon <(handle) text...>)

For an example file, check http://guerrerovolador.com/airspace.xhtml
