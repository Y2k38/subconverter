defmodule Subconverter.CLI.Export do
  @moduledoc """
  Handles the `export` subcommand to generate client-specific import URLs or QRCodes.
  """

  def run(["help"]), do: print_help()
  def run(options) do
    parsed = parse_options(options)

    case Map.get(parsed, :type) do
      "clash" -> generate_clash(parsed)
      "shadowrocket" -> generate_shadowrocket(parsed)
      nil ->
        IO.puts("❌ Error: Missing --type. Please specify 'clash' or 'shadowrocket'.\n")
        print_help()
      other ->
        IO.puts("❌ Error: Unknown type '#{other}'.\n")
        print_help()
    end
  end

  defp parse_options(options) do
    {parsed, _args, _invalid} =
      OptionParser.parse(options,
        strict: [type: :string, url: :string, name: :string, qrcode: :boolean, out: :string]
      )

    Map.new(parsed)
  end

  defp generate_clash(%{url: url, name: name} = opts) do
    encoded_url = URI.encode_www_form(url)
    encoded_name = URI.encode_www_form(name)
    clash_url = "clash://install-config?url=#{encoded_url}&name=#{encoded_name}"

    output_result(clash_url, opts)
  end
  defp generate_clash(_), do: IO.puts("❌ Error: Missing required arguments --url and/or --name")

  defp generate_shadowrocket(%{url: url, name: name} = opts) do
    b64_url = Base.encode64(url)
    encoded_remark = URI.encode_www_form(name)
    sr_url = "shadowrocket://add/sub://#{b64_url}?remark=#{encoded_remark}"

    output_result(sr_url, opts)
  end
  defp generate_shadowrocket(_), do: IO.puts("❌ Error: Missing required arguments --url and/or --name")

  defp output_result(final_url, opts) do
    cond do
      opts[:qrcode] && opts[:out] ->
        # Save to file ONLY, no terminal output
        png_data = final_url |> EQRCode.encode() |> EQRCode.png(width: 800)
        File.write!(opts[:out], png_data)
        IO.puts("✅ Successfully saved high-definition QRCode to: #{opts[:out]}")

      opts[:qrcode] ->
        # Render ASCII QRCode in terminal ONLY
        final_url |> EQRCode.encode() |> EQRCode.render()

      true ->
        # Just print the URL text
        IO.puts(final_url)

        if opts[:out] do
          IO.puts("\n⚠️ Warning: --out flag was ignored because --qrcode was not specified.")
        end
    end
  end

  defp print_help do
    IO.puts("""
    [export] Export configuration as a one-click import URL or QRCode.

    Usage:
      subconverter export [options]

    Options:
      --type    Target client (required: clash or shadowrocket)
      --url     Original subscription URL (required)
      --name    Configuration name or remark (required)
      --qrcode  Print a terminal QRCode instead of just text (optional)
      --out     Save QRCode to a PNG image file (must be combined with --qrcode)

    Example URL:
      subconverter export --type clash --url "http://example.com/sub" --name "My Config"

    Example Terminal QRCode:
      subconverter export --type shadowrocket --url "http://example.com/sub" --name "My Config" --qrcode

    Example QRCode + HD Image:
      subconverter export --type shadowrocket --url "http://example.com/sub" --name "My Config" --qrcode --out my_qr.png
    """)
  end
end
