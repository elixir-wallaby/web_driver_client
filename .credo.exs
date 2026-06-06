%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          {Credo.Check.Refactor.Nesting, max_nesting: 3}
        ]
      }
    }
  ]
}
