require 'rails_helper'

describe Twitter::Api do
  it 'can make a request for the twitter timeline' do
    body = File.read("./spec/support/twitter_responses/timeline_response_count_2.json")

    stub_request(:get, "https://api.twitter.com/1.1/statuses/home_timeline.json?count=5").
      to_return(status: 200, body: body)

    user = create_user
    create_twitter_account(user)

    parsed_body = Oj.load(body)

    tweet_1 = Twitter::Tweet.new(parsed_body.first.symbolize_keys)
    tweet_2 = Twitter::Tweet.new(parsed_body.last.symbolize_keys)

    twitter_api = Twitter::Api.new(user)
    response = twitter_api.feed

    expect(response.body).to eq [tweet_1, tweet_2]
    expect(response.code).to eq 200
  end

  it 'will return a NullResponse object if a user does not have a twitter account' do
    user = create_user
    twitter_api = Twitter::Api.new(user)
    response = twitter_api.feed
    expect(response.body).to eq []
    expect(response.code).to eq 204
  end

  it 'will raise an error if a user is no longer authorized' do
    body = {
      "errors" => [
        {
          "message" => "Bad Authentication data",
          "code" => 215
        }
      ]
    }.to_json

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/home_timeline.json?count=5').
      to_return(status: 401, body: body)

    user = create_user
    create_twitter_account(user)
    allow(Twitter::REST::Client).to receive(:home_timeline).and_raise(Twitter::Error::Unauthorized)
    twitter_api = Twitter::Api.new(user)
    response = twitter_api.feed

    expect(response.body).to eq []
    expect(response.code).to eq 401
  end

  it 'can make a request with pagination' do
    body = File.read('./spec/support/twitter_responses/timeline_response_count_5.json')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/home_timeline.json?count=26&max_id=462323298248843264').
      to_return(status: 200, body: body)

    user = create_user
    create_twitter_account(user)

    parsed_body = Oj.load(body)

    tweet_1 = Twitter::Tweet.new(parsed_body[1].symbolize_keys)
    tweet_2 = Twitter::Tweet.new(parsed_body[2].symbolize_keys)
    tweet_3 = Twitter::Tweet.new(parsed_body[3].symbolize_keys)
    tweet_4 = Twitter::Tweet.new(parsed_body[4].symbolize_keys)

    twitter_api = Twitter::Api.new(user)
    response = twitter_api.feed("462323298248843264")
    expect(response.body).to eq [tweet_1, tweet_2, tweet_3, tweet_4]
    expect(response.code).to eq 200
  end
end