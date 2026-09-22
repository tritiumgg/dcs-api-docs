---@meta
-- What DCS provides to the instrument, declared for the language server.
--
-- A ---@meta file rather than a diagnostics.globals list: a globals list
-- silences a misspelt DCS call along with the right one, while a declaration
-- makes the misspelling a finding. Add here only what DcsApiCensus.lua and
-- the harness actually use. Cataloguing the DCS API is the product, not this
-- file.

---@class lfs
---@field writedir fun(): string
---@field tempdir fun(): string
---@field currentdir fun(): string
---@field attributes fun(path: string, attr?: string): any
lfs = {}

---@class net
---@field dostring_in fun(state: string, chunk: string): string?, string?
net = {}
