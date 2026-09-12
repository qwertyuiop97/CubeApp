.PHONY: build run test clean

# Keep the SDK paired with the selected Xcode toolchain, rather than inheriting
# a CommandLineTools SDK from the launching shell. Override on make's command
# line when deliberately testing another SDK: make SDKROOT=/path/to/sdk build.
export SDKROOT := $(shell xcrun --sdk macosx --show-sdk-path)

build:
	swift build -Xswiftc -warnings-as-errors

run:
	swift run

test:
	swift test -Xswiftc -warnings-as-errors
	python3 Scripts/test_audit_primary_algs_source_compare.py -v

clean:
	swift package clean
