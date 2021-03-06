ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += file
FILE_VERSION   := 5.39
DEB_FILE_V     ?= $(FILE_VERSION)-1

file-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) ftp://ftp.astron.com/pub/file/file-$(FILE_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,file-$(FILE_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,file-$(FILE_VERSION).tar.gz,file-$(FILE_VERSION),file)

ifneq ($(wildcard $(BUILD_WORK)/file/.build_complete),)
file:
	@echo "Using previously built file."
else
file: file-setup xz
	rm -rf $(BUILD_WORK)/../../native/file
	mkdir -p $(BUILD_WORK)/../../native/file
	+unset CC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS; \
		cd $(BUILD_WORK)/../../native/file && $(BUILD_WORK)/file/configure; \
		$(MAKE) -C $(BUILD_WORK)/../../native/file
	cd $(BUILD_WORK)/file && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-libseccomp \
		--enable-fsect-man5
	+$(MAKE) -C $(BUILD_WORK)/file \
		FILE_COMPILE="$(BUILD_WORK)/../../native/file/src/file"
	+$(MAKE) -C $(BUILD_WORK)/file install \
		DESTDIR="$(BUILD_STAGE)/file"
	+$(MAKE) -C $(BUILD_WORK)/file install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/file/.build_complete
endif

file-package: file-stage
	# file.mk Package Structure
	rm -rf $(BUILD_DIST)/file $(BUILD_DIST)/libmagic{1,-dev}
	mkdir -p $(BUILD_DIST)/file/usr/share/man \
		$(BUILD_DIST)/libmagic1/usr/{lib,share} \
		$(BUILD_DIST)/libmagic-dev/usr/{lib,share/man}
	
	# file.mk Prep file
	cp -a $(BUILD_STAGE)/file/usr/bin $(BUILD_DIST)/file/usr
	cp -a $(BUILD_STAGE)/file/usr/share/man/man1 $(BUILD_DIST)/file/usr/share/man

	# file.mk Prep libmagic1
	cp -a $(BUILD_STAGE)/file/usr/lib/libmagic.1.dylib $(BUILD_DIST)/libmagic1/usr/lib
	cp -a $(BUILD_STAGE)/file/usr/share/man/man5 $(BUILD_DIST)/libmagic1/usr/share/man
	cp -a $(BUILD_STAGE)/file/usr/share/misc $(BUILD_DIST)/libmagic1/usr/share

	# file.mk Prep libmagic-dev
	cp -a $(BUILD_STAGE)/file/usr/lib/!(libmagic.1.dylib) $(BUILD_DIST)/libmagic-dev/usr/lib
	cp -a $(BUILD_STAGE)/file/usr/share/man/man3 $(BUILD_DIST)/libmagic-dev/usr/share/man
	
	# file.mk Sign
	$(call SIGN,file,general.xml)
	$(call SIGN,libmagic1,general.xml)
	
	# file.mk Make .debs
	$(call PACK,file,DEB_FILE_V)
	$(call PACK,libmagic1,DEB_FILE_V)
	$(call PACK,libmagic-dev,DEB_FILE_V)
	
	# file.mk Build cleanup
	rm -rf $(BUILD_DIST)/file $(BUILD_DIST)/libmagic{1,-dev}

.PHONY: file file-package
