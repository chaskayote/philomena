defmodule Philomena.Scrapers.Twitter do
  @url_regex ~r|\Ahttps?://(?:mobile\.)?(?:twitter\|x).com/([A-Za-z\d_]+)/status/([\d]+)/?|

  @spec can_handle?(URI.t(), String.t()) :: true | false
  def can_handle?(_uri, url) do
    String.match?(url, @url_regex)
  end

  def scrape(_uri, url) do
    [user, status_id] = Regex.run(@url_regex, url, capture: :all_but_first)

    api_url = "https://api.fxtwitter.com/#{user}/status/#{status_id}"
    {:ok, %Tesla.Env{status: 200, body: body}} = Philomena.Http.get(api_url)

    json = Jason.decode!(body)
    tweet = json["tweet"]

    images =
      Enum.map(tweet["media"]["photos"], fn p ->
        %{
          url: "#{p["url"]}:orig",
          camo_url: Camo.Image.image_url(p["url"])
        }
      end)

    %{
      source_url: tweet["url"],
      author_name: tweet["author"]["screen_name"],
      description: tweet["text"],
      images: images
    }
  end
end
