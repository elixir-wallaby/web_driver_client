# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:stream_data],
  locals_without_parens: [
    # Wallaby.CompatabilityMacros
    doc_metadata: 1,
    prerelease_moduledoc: 1
  ]
]
