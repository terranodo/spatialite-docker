FROM alpine as build

RUN echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@edge-testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk update && \
  apk --no-cache --update upgrade musl && \
  apk add --upgrade apk-tools@edge && \
  apk add --update wget gcc make automake libtool autoconf fossil git libc-dev sqlite-dev zlib-dev libxml2-dev "proj4-dev@edge-testing" "geos-dev@edge-testing" "gdal-dev@edge-testing" "gdal@edge-testing" expat-dev readline-dev ncurses-dev readline ncurses-static libc6-compat && \
  rm -rf /var/cache/apk/*

ENV USER me

RUN fossil clone https://www.gaia-gis.it/fossil/freexl freexl.fossil && mkdir freexl && cd freexl && fossil open ../freexl.fossil && ./configure && make -j8 && make install

RUN git clone "https://git.osgeo.org/gitea/rttopo/librttopo.git" && cd librttopo && ./autogen.sh && ./configure && make -j8 && make install

RUN fossil clone https://www.gaia-gis.it/fossil/libspatialite libspatialite.fossil && mkdir libspatialite && cd libspatialite && fossil open ../libspatialite.fossil && ./configure --enable-rttopo --enable-geocallbacks --enable-gcp=yes --enable-libxml2 && make -j8 && make install

RUN fossil clone https://www.gaia-gis.it/fossil/readosm readosm.fossil && mkdir readosm && cd readosm && fossil open ../readosm.fossil && ./configure && make -j8 && make install

RUN fossil clone https://www.gaia-gis.it/fossil/spatialite-tools spatialite-tools.fossil && mkdir spatialite-tools && cd spatialite-tools && fossil open ../spatialite-tools.fossil && ./configure && make -j8 && make install

RUN cp /usr/local/bin/* /usr/bin/
RUN cp -R /usr/local/lib/* /usr/lib/

# Create a minimal instance
FROM alpine

COPY --from=build /usr/lib/ /usr/lib
COPY --from=build /usr/bin/ /usr/bin

ENTRYPOINT ["spatialite"]
