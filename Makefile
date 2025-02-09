.PHONY: rpm
rpm:
	OS=el DIST=7 packpack/packpack

.rocks: metrics-scm-1.rockspec
	tarantoolctl rocks make
	tarantoolctl rocks install luatest 0.5.7
	tarantoolctl rocks install luacov 0.13.0
	tarantoolctl rocks install luacheck 0.26.0
	if [ -n '$(CARTRIDGE_VERSION)' ]; then \
		tarantoolctl rocks install cartridge $(CARTRIDGE_VERSION); \
	fi

.PHONY: lint
lint: .rocks
	.rocks/bin/luacheck .

.PHONY: test
test: .rocks
	.rocks/bin/luatest -v

.PHONY: test_with_coverage_report
test_with_coverage_report: .rocks
	rm -f tmp/luacov.*.out*
	.rocks/bin/luatest --coverage -v --shuffle group --repeat 3
	.rocks/bin/luacov .
	echo
	grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: test_promtool
test_promtool: .rocks
	tarantool test/promtool.lua
	cat prometheus-input | promtool check metrics
	rm prometheus-input

update-pot:
	sphinx-build doc/monitoring doc/locale/en/ -c doc/ -d doc/.doctrees -b gettext

update-po:
	sphinx-intl update -p doc/locale/en/ -d doc/locale/ -l "ru"

.PHONY: clean
clean:
	rm -rf .rocks
