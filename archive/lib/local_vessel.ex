defmodule Mix.Tasks.Local.Vessel do
  use Mix.Task

  # shortdoc for mix metadata
  @shortdoc "Updates Vessel tasks locally"

  # github repo metadata
  @git_auth "zackehh"
  @git_repo "vessel"
  @git_arch ".ez"

  @moduledoc """
  Updates Vessel locally.

  This will pull the latest GitHub release and install it locally.

  ## Examples

      $ mix local.vessel

  Accepts the same command line options as `archive.install`.
  """
  def run(args) do
    { :ok, _ } = Application.ensure_all_started(:tentacat)

    Tentacat.Client.new()
    |> get_releases
    |> find_archive
    |> find_url
    |> install(args)
  end

  # Retrieves the release list from the GitHub, pulling back using the module
  # attributes to designate the repo author and repo name.
  defp get_releases(client),
    do: Tentacat.Releases.list(@git_auth, @git_repo, client)

  # Finds the latest release archive to install. Typically this is just plucking
  # the first release, as that's the latest. However, we do a search just to make
  # this a little more resilient to error.
  #
  # We just find the latest release with a `.ez` binary attached and use that to
  # install - this removes the need to publish the same installer again in case
  # it has not changed since the previous version. It also means that we don't
  # hardcode the archive name at any point, again to avoid mistakes.
  #
  # Although this is a linear search, because the latest release is typically
  # the first, this should be O(1) most of the time so it's not a concern for
  # slowness.
  defp find_archive(%{ "assets" => assets }) do
    case Enum.find(assets, &do_rel_search/1) do
      nil -> Mix.raise("Unable to locate release archive!")
      val -> val
    end
  end

  # Plucks out a URL for the .ez archive download if possible. If there is no
  # download, then we raise an error. Likely never happen, but just to be safe.
  defp find_url(%{ "browser_download_url" => url }),
    do: url
  defp find_url(_error),
    do: Mix.raise("Unable to find browser download url!")

  # Installs the archive from the provided URL, passing through any arguments to
  # let the user control how they install the archive (this is just a passthrough).
  defp install(url, args),
    do: Mix.Task.run("archive.install", [ url | args ])

  # Searches through assets inside a release and returns true if any of the assets
  # are a .ez archive (which means they contain a new installer version).
  defp do_rel_search(assets),
    do: Enum.any?(assets, &do_ext_search/1)

  # Determines whether an asset has an archive extension. We do this by just using
  # the String lib to look at the `name` field if it exists. If it doesn't, it's
  # an automatic false reply, because all archives should be named.
  defp do_ext_search(%{ "name" => name }),
    do: String.ends_with?(name, @git_arch)
  defp do_ext_search(_invalid),
    do: false

end
