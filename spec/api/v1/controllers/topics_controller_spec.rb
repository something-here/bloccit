require 'rails_helper'

RSpec.describe Api::V1::TopicsController, type: :controller do
  let(:my_user) { create(:user) }
  let(:my_topic) { create(:topic, user: my_user ) }

  context "unauthenticated user" do
    it "GET index returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "GET show returns http success" do
      get :show, params: {id: my_topic.id}
      expect(response).to have_http_status(:success)
    end

    it "PUT update returns http unauthenticated" do
      put :update, params: {id: my_topic.id, topic: {name: "Topic Name", description: "Topic Description"}}
      expect(response).to have_http_status(401)
    end

    it "POST create returns http unauthenticated" do
      post :create, params: {topic: {name: "Topic Name", description: "Topic Description"}}
      expect(response).to have_http_status(401)
    end

    it "DELETE destroy returns http unauthenticated" do
      delete :destroy, params: {id: my_topic.id}
      expect(response).to have_http_status(401)
    end
  end

  context "unauthorized user" do
    before do
      controller.request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(my_user.auth_token)
    end

    it "GET index returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "GET show returns http success" do
      get :show, params: {id: my_topic.id}
      expect(response).to have_http_status(:success)
    end

    it "PUT update returns http forbidden" do
      put :update, params: {id: my_topic.id, topic: {name: "Topic Name", description: "Topic Description"}}
      expect(response).to have_http_status(403)
    end

    it "POST create returns http forbidden" do
      post :create, params: {topic: {name: "Topic Name", description: "Topic Description"}}
      expect(response).to have_http_status(403)
    end

    it "DELETE destroy returns http forbidden" do
      delete :destroy, params: {id: my_topic.id}
      expect(response).to have_http_status(403)
    end
  end

  context "authenticated and authorized users" do
    before do
      my_user.admin!
      controller.request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(my_user.auth_token)
      @new_topic = build(:topic)
    end

    describe "PUT update" do
      before { put :update, params: {id: my_topic.id, topic: {name: @new_topic.name, description: @new_topic.description, user: my_user}} }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns json content type" do
        expect(response.content_type).to eq 'application/json'
      end

      it "updates a topic with the correct attributes" do
        updated_topic = Topic.find(my_topic.id)
        hashed_json = JSON.parse(response.body)
        expect(hashed_json['name']).to eq(updated_topic.name)
        expect(hashed_json['description']).to eq(updated_topic.description)
      end
    end

    describe "POST create" do
      before { post :create, params: {topic: {name: @new_topic.name, description: @new_topic.description, user: my_user} }}

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns json content type" do
        expect(response.content_type).to eq 'application/json'
      end

      it "creates a topic with the correct attributes" do
        hashed_json = JSON.parse(response.body)
        expect(hashed_json["name"]).to eq(@new_topic.name)
        expect(hashed_json["description"]).to eq(@new_topic.description)
      end
    end

    describe "DELETE destroy" do
      before do
        delete :destroy, params: {id: my_topic.id}
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns json content type" do
        expect(response.content_type).to eq 'application/json'
      end

      it "returns the correct json success message" do
        expect(response.body).to eq({ message: "Topic destroyed", status: 200 }.to_json)
      end

      it "deletes my_topic" do
        expect{ Topic.find(my_topic.id) }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
