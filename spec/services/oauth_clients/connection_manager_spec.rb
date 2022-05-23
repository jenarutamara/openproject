#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe ::OAuthClients::ConnectionManager, type: :model do
  let(:current_user) { create :user }
  let(:oauth_client) { create :oauth_client }
  let(:oauth_client_token) do
    create(:oauth_client_token,
           user: current_user,
           oauth_client: oauth_client)
  end
  let(:instance) { described_class.new(user: current_user, oauth_client: oauth_client) }
  let(:state) { "/some_url_the_user_came_from" }

  describe '#get_access_token' do
    subject { instance.get_access_token(state) }

    context 'with an OAuthClientToken present' do
      before do
        oauth_client_token
      end

      it 'returns the OAuthClientToken' do
        expect(subject.success?).to be_truthy
        expect(subject.result).to be_a OAuthClientToken
      end
    end

    context 'without an OAuthClientToken present' do
      it 'returns the redirect URL' do
        expect(subject.success?).to be_falsey
        expect(subject.result).to be_a String
        expect(subject.result).to include oauth_client.integration.host
      end
    end
  end
end
