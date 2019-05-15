defmodule ReleaseManager.Plugin.Consolidation do
  @name "protocol.consolidation"
  @shortdoc "Performs protocol consolidation for your release."

  use    ReleaseManager.Plugin
  alias  ReleaseManager.Config
  alias  ReleaseManager.Utils
  import ReleaseManager.Utils, except: [debug: 1, info: 1, warn: 1, error: 1]

  def before_release(%Config{verbosity: verbosity, env: env} = config) do
    build_embedded = Keyword.get(Mix.Project.config, :build_embedded, false)
    should_compile = env != :test && !build_embedded
    if should_compile do
      debug "Performing protocol consolidation..."
      with_env env, fn ->
        cond do
          verbosity == :verbose ->
            mix "compile.protocols", env, :verbose
          true ->
            mix "compile.protocols", env
        end
      end
    end

    # Load relx.config
    if env != :test do
      debug "Packaging consolidated protocols..."

      # Add overlay to relx.config which copies consolidated dir to release
      consolidated_path = Path.join([Mix.Project.build_path, "consolidated"])
      case File.ls(consolidated_path) do
        {:error, _} ->
          config
        {:ok, filenames} ->
          dest_path = "lib/#{config.name}-#{config.version}/consolidated"
          overlays = [overlay: Enum.map(filenames, fn name ->
            {:copy, '#{consolidated_path}/#{name}', '#{Path.join([dest_path, name])}'}
          end)]
          updated = Utils.merge(config.relx_config, overlays)
          %{config | :relx_config => updated}
      end
    else
      config
    end
  end

  def after_release(_), do: nil
  def after_package(_), do: nil
  def after_cleanup(_), do: nil
end
