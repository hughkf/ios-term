BUILDDIR	= ./build
SOURCEDIR	= .
APPNAME   = Terminal
APPDIR		= ./$(APPNAME).app

#all: copySources Terminal package sendToiPod killOniPod startOniPod removeSources done
all: copySources depend Terminal package sendToiPod killOniPod done

svnversion:
	$(shell python svnversion.py)

copySources:
	@echo ... copying sources ...
	$(shell mkdir -p $(BUILDDIR))
	$(shell rm -f $(BUILDDIR)/Makefile)
	$(shell cp -p ./Makefile.build $(BUILDDIR)/Makefile)
	$(shell find $(SOURCEDIR) \( -name "*.m" -or -name "*.h" \) -type f \! -path "./build/*" -exec cp -p -f {} $(BUILDDIR) \;)

depend:
	@echo ... updating dependencies ...
	$(shell make -C $(BUILDDIR) depend)

Terminal:
	@echo ... building $(APPNAME) ...
	make -C $(BUILDDIR) $(APPNAME)

package:
	@echo ... packaging $(APPNAME).app ...
	$(shell rm -fr $(APPDIR))
	$(shell mkdir -p $(APPDIR))
	$(shell cp $(BUILDDIR)/$(APPNAME) $(APPDIR)/)
	$(shell cp Info.plist $(APPDIR)/Info.plist)
	$(shell cp -r ./Resources/* $(APPDIR)/)
	$(shell find $(APPDIR) -name ".svn" | xargs rm -Rf)

sendToiPod:
	@echo ... sending to iPod ...
	scp -r $(APPDIR) root@$(IPHONE_IP):/Applications/
	
killOniPod:
	@echo ... killing $(APPNAME) on iPod ...
	$(shell ssh root@$(IPHONE_IP) killall $(APPNAME))

startOniPod:
	@echo ... starting $(APPNAME) on iPod ...
	ssh root@$(IPHONE_IP) /Applications/$(APPNAME).app/$(APPNAME) ls

removeSources:
	@echo ... removing sources ...
	$(shell rm -f $(BUILDDIR)/*.c $(BUILDDIR)/*.h $(BUILDDIR)/*.m)

clean: 
	@echo ... cleaning up ...
	rm -fr $(BUILDDIR)
	rm -fr *.o $(APPNAME).app $(APPNAME).zip

dist: svnversion copySources depend Terminal package
	zip -r $(APPNAME).zip $(APPDIR)

done:
	@echo ... done

