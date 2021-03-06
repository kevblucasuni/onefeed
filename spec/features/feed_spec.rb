require 'rails_helper'

feature 'streaming a users feed', js: true do
  context "getting the feed" do
    scenario 'when a user logs in with Instagram they will see their feed at /feed' do
      body = File.read('./spec/support/instagram_responses/timeline_response_count_5.json')
      stub_request(:get, 'https://api.instagram.com/v1/users/self/feed?access_token=mock_token&count=5').
        to_return(status: 200, body: body)

      mock_auth_hash
      user = create_user
      login_user(user)
      expect(page).to have_content 'Click on one of the providers below or visit "My Account" to link an account and get started'
      find(:xpath, "//a[contains(@href,'/auth/instagram')]").click
      expect(page).to have_content 'Unicorns do exist! #magic #unicorns #denvercountyfair'
      expect(page).to have_content 'Climbing up the steps of #SaintJosephsOratory'
    end

    scenario 'a user will see a message if they try to login with an invalid Instagram token' do
      body = {
        'meta' => {
          'error_type' => 'OAuthParameterException',
          'code' => 400,
          'error_message' => 'The access_token provided is invalid.'
        }
      }.to_json
      stub_request(:get, 'https://api.instagram.com/v1/users/self/feed?access_token=mock_token&count=5').
        to_return(status: 400, body: body)

      user = create_user
      login_user(user)
      click_link 'My Account'
      find(:xpath, "//a[contains(@href,'/auth/instagram')]").click
      expect(page).to have_content 'Your account is no longer authorized. Please reauthorize the following accounts on your account page: Instagram.'
      expect(page).to_not have_content 'You have successfully logged in with Instagram'
    end

    scenario 'a user can click on the load more posts button and it will make a request to get more Instagram posts' do
      body1 = File.read('./spec/support/instagram_responses/timeline_response_count_5.json')
      body2 = File.read('./spec/support/instagram_responses/timeline_response_count_25.json')
      stub_request(:get, 'https://api.instagram.com/v1/users/self/feed?access_token=mock_token&count=5').
        to_return(status: 200, body: body1)
      stub_request(:get, 'https://api.instagram.com/v1/users/self/feed?access_token=mock_token&count=25&max_id=776999430264003590_1081226094').
        to_return(status: 200, body: body2)

      mock_auth_hash
      user = create_user
      login_user(user)
      click_link 'My Account'
      find(:xpath, "//a[contains(@href,'/auth/instagram')]").click
      find('.load-more-link').click
      expect(page).to have_content 'Pool time #mtl'
    end

    scenario 'a user can stream Twitter posts' do
      mock_auth_hash
      body = File.read('./spec/support/twitter_responses/timeline_response_count_5.json')
      stub_request(:get, 'https://api.twitter.com/1.1/statuses/home_timeline.json?count=5').
        to_return(status: 200, body: body)
      user = create_user
      login_user(user)
      find(:xpath, "//a[contains(@href,'/auth/twitter')]").click
      expect(page).to have_content 'Gillmor Gang Live 05.02.14 http://t.co/WmzFBbPKUr by @stevegillmor'
    end

    scenario 'user can click on the load more posts button and it will make a request to get more Tweets' do
      mock_auth_hash
      body1 = File.read('./spec/support/twitter_responses/timeline_response_count_5.json')
      body2 = File.read('./spec/support/twitter_responses/timeline_response_count_20.json')
      stub_request(:get, 'https://api.twitter.com/1.1/statuses/home_timeline.json?count=5').
        to_return(status: 200, body: body1)
      stub_request(:get, 'https://api.twitter.com/1.1/statuses/home_timeline.json?count=26&max_id=462321101763522561').
        to_return(status: 200, body: body2)

      user = create_user
      login_user(user)
      click_link 'My Account'
      find(:xpath, "//a[contains(@href,'/auth/twitter')]").click

      expect(page).to have_content 'Gillmor Gang Live 05.02.14 http://t.co/WmzFBbPKUr by @stevegillmor'
      find('.load-more-link').click
      expect(page).to have_content 'Announcing Your Disrupt NY Startup Battlefield Final Judges http://t.co/zm8wpmwPbp by @alexia'
    end

    scenario 'a user can stream Facebook posts' do
      mock_auth_hash
      body = File.read('./spec/support/facebook_responses/timeline_response_count_2.json')
      stub_request(:get, 'https://graph.facebook.com/v2.0/me/home?access_token=mock_token&limit=5').
        to_return(status: 200, body: body)
      user = create_user
      login_user(user)
      find(:xpath, "//a[contains(@href,'/auth/facebook')]").click
      expect(page).to have_content 'Garden Watch: 8/11/2014 http://wp.me/p4pM8M-h0'
    end

    scenario 'user can click on the load more posts button and it will make a request to get more Facebook posts' do
      mock_auth_hash
      body1 = File.read('./spec/support/facebook_responses/timeline_response_count_2.json')
      body2 = File.read('./spec/support/facebook_responses/timeline_response_count_3.json')
      stub_request(:get, 'https://graph.facebook.com/v2.0/me/home?access_token=mock_token&limit=5').
        to_return(status: 200, body: body1)
      stub_request(:get, 'https://graph.facebook.com/v2.0/me/home?access_token=mock_token&limit=25&until=1407764111').
        to_return(status: 200, body: body2)

      user = create_user
      login_user(user)
      click_link 'My Account'
      find(:xpath, "//a[contains(@href, 'auth/facebook')]").click
      expect(page).to have_content 'Garden Watch:'
      find('.load-more-link').click
      expect(page).to have_content 'The start of the new season. Transfer window is still open, and teams are still getting back to full fitness. Its time to scout out your players and make your fantasy picks. Before that, have a listen and ask a question. The CoshCast is heating up!'
    end
  end

  context "formatting the feed" do
    scenario 'links are wrapped in link tags' do
      mock_auth_hash
      body = File.read('./spec/support/twitter_responses/timeline_response_count_5.json')
      stub_request(:get, 'https://api.twitter.com/1.1/statuses/home_timeline.json?count=5').
        to_return(status: 200, body: body)
      user = create_user
      login_user(user)
      click_link 'My Account'
      find(:xpath, "//a[contains(@href,'/auth/twitter')]").click
      expect(page).to have_link 'http://t.co/WmzFBbPKUr'
    end
  end
end
