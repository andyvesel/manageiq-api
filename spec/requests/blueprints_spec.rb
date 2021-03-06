RSpec.describe "Blueprints API" do
  describe "GET /api/blueprints" do
    it "lists all the blueprints with an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize collection_action_identifier(:blueprints, :read, :get)

      get(api_blueprints_url)

      expected = {
        "count"     => 1,
        "subcount"  => 1,
        "name"      => "blueprints",
        "resources" => [
          hash_including("href" => api_blueprint_url(nil, blueprint))
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "forbids access to blueprints without an appropriate role" do
      FactoryGirl.create(:blueprint)
      api_basic_authorize

      get(api_blueprints_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/blueprints/:id" do
    it "will show a blueprint with an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize action_identifier(:blueprints, :read, :resource_actions, :get)

      get(api_blueprint_url(nil, blueprint))

      expect(response.parsed_body).to include("href" => api_blueprint_url(nil, blueprint))
      expect(response).to have_http_status(:ok)
    end

    it "forbids access to a blueprint without an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize

      get(api_blueprint_url(nil, blueprint))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/blueprints" do
    it "can create a blueprint" do
      api_basic_authorize collection_action_identifier(:blueprints, :create)
      ui_properties = {
        :service_catalog      => {},
        :service_dialog       => {},
        :automate_entrypoints => {},
        :chart_data_model     => {}
      }

      post(api_blueprints_url, :params => { :name => "foo", :description => "bar", :ui_properties => ui_properties })

      expected = {
        "results" => [
          a_hash_including(
            "name"          => "foo",
            "description"   => "bar",
            "ui_properties" => {
              "service_catalog"      => {},
              "service_dialog"       => {},
              "automate_entrypoints" => {},
              "chart_data_model"     => {}
            }
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "rejects blueprint creation with id specified" do
      api_basic_authorize collection_action_identifier(:blueprints, :create)

      post(api_blueprints_url, :params => { :name => "foo", :description => "bar", :id => 123 })

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => a_string_matching(/id or href should not be specified/i),
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it "rejects blueprint creation with an href specified" do
      api_basic_authorize collection_action_identifier(:blueprints, :create)

      post(api_blueprints_url, :params => { :name => "foo", :description => "bar", :href => api_blueprint_url(nil, 123) })

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => a_string_matching(/id or href should not be specified/i),
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end

    it "can create blueprints in bulk" do
      api_basic_authorize collection_action_identifier(:blueprints, :create)
      ui_properties = {
        :service_catalog      => {},
        :service_dialog       => {},
        :automate_entrypoints => {},
        :chart_data_model     => {}
      }

      post(
        api_blueprints_url,
        :params => {
          :resources => [
            {:name => "foo", :description => "bar", :ui_properties => ui_properties},
            {:name => "baz", :description => "qux", :ui_properties => ui_properties}
          ]
        }
      )

      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including("name" => "foo", "description" => "bar", "href" => a_string_including(api_blueprints_url)),
          a_hash_including("name" => "baz", "description" => "qux", "href" => a_string_including(api_blueprints_url))
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "forbids blueprint creation without an appropriate role" do
      api_basic_authorize

      post(api_blueprints_url, :params => { :name => "foo", :description => "bar", :ui_properties => {:some => {:json => "baz"}} })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/blueprints" do
    it "can update attributes of multiple blueprints with an appropirate role" do
      blueprint1 = FactoryGirl.create(:blueprint, :name => "foo")
      blueprint2 = FactoryGirl.create(:blueprint, :name => "bar")
      api_basic_authorize collection_action_identifier(:blueprints, :edit)

      post(
        api_blueprints_url,
        :params => {
          :action    => "edit",
          :resources => [
            {:id => blueprint1.id, :name => "baz"},
            {:id => blueprint2.id, :name => "qux"}
          ]
        }
      )

      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including(
            "id"   => blueprint1.id.to_s,
            "name" => "baz"
          ),
          a_hash_including(
            "id"   => blueprint2.id.to_s,
            "name" => "qux"
          )
        )
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "forbids the updating of multiple blueprints without an appropriate role" do
      blueprint1 = FactoryGirl.create(:blueprint, :name => "foo")
      blueprint2 = FactoryGirl.create(:blueprint, :name => "bar")
      api_basic_authorize

      post(
        api_blueprints_url,
        :params => {
          :action    => "edit",
          :resources => [
            {:id => blueprint1.id, :name => "baz"},
            {:id => blueprint2.id, :name => "qux"}
          ]
        }
      )

      expect(response).to have_http_status(:forbidden)
    end

    it "can delete multiple blueprints" do
      blueprint1, blueprint2 = FactoryGirl.create_list(:blueprint, 2)
      api_basic_authorize collection_action_identifier(:blueprints, :delete)

      post(api_blueprints_url, :params => { :action => "delete", :resources => [{:id => blueprint1.id}, {:id => blueprint2.id}] })

      expect(response).to have_http_status(:ok)
    end

    it "forbids multiple blueprint deletion without an appropriate role" do
      blueprint1, blueprint2 = FactoryGirl.create_list(:blueprint, 2)
      api_basic_authorize

      post(api_blueprints_url, :params => { :action => "delete", :resources => [{:id => blueprint1.id}, {:id => blueprint2.id}] })

      expect(response).to have_http_status(:forbidden)
    end

    it "can publish multiple blueprints" do
      service_template = FactoryGirl.create(:service_template)
      dialog = FactoryGirl.create(:dialog_with_tab_and_group_and_field)
      ui_properties = {
        "service_dialog"        => {"id" => dialog.id},
        "chart_data_model"      => {
          "nodes" => [{
            "id"   => service_template.id,
            "tags" => []
          }]},
        "automate_entry_points" => {
          "Reconfigure" => "foo",
          "Provision"   => "bar"
        }
      }
      blueprint1, blueprint2 = FactoryGirl.create_list(:blueprint, 2, :ui_properties => ui_properties)

      api_basic_authorize collection_action_identifier(:blueprints, :publish)

      post(api_blueprints_url, :params => { :action => "publish", :resources => [{:id => blueprint1.id}, {:id => blueprint2.id}] })

      expected = {
        "results" => a_collection_containing_exactly(
          a_hash_including("id" => blueprint1.id.to_s, "status" => "published"),
          a_hash_including("id" => blueprint2.id.to_s, "status" => "published")
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/blueprints/:id" do
    it "forbids the updating of blueprints without an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint, :name => "foo", :description => "bar")
      api_basic_authorize

      post(api_blueprint_url(nil, blueprint), :params => { :action => "edit", :resource => {:name => "baz", :description => "qux"} })

      expect(response).to have_http_status(:forbidden)
    end

    it "can delete a blueprint with an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize action_identifier(:blueprints, :delete)

      post(api_blueprint_url(nil, blueprint), :params => { :action => "delete" })

      expect(response).to have_http_status(:ok)
    end

    it "forbids blueprint deletion without an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize

      post(api_blueprint_url(nil, blueprint), :params => { :action => "delete" })

      expect(response).to have_http_status(:forbidden)
    end

    it "publishes a single blueprint" do
      service_template = FactoryGirl.create(:service_template)
      dialog = FactoryGirl.create(:dialog_with_tab_and_group_and_field)
      ui_properties = {
        "service_dialog"        => {"id" => dialog.id},
        "chart_data_model"      => {
          "nodes" => [{
            "id"   => service_template.id,
            "tags" => []
          }]},
        "automate_entry_points" => {
          "Reconfigure" => "foo",
          "Provision"   => "bar"
        }
      }
      blueprint = FactoryGirl.create(:blueprint, :ui_properties => ui_properties)
      api_basic_authorize action_identifier(:blueprints, :publish)

      post(api_blueprint_url(nil, blueprint), :params => { :action => "publish" })

      expected = {
        "id"     => blueprint.id.to_s,
        "status" => "published"
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "fails appropriately if a blueprint publish raises" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize action_identifier(:blueprints, :publish)

      post(api_blueprint_url(nil, blueprint), :params => { :action => "publish" })

      expected = {
        "error" => a_hash_including(
          "kind"    => "bad_request",
          "message" => a_string_matching(/Failed to publish blueprint - /i),
        )
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /api/blueprints/:id" do
    it "can delete a blueprint with an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize action_identifier(:blueprints, :delete, :resource_actions, :delete)

      delete(api_blueprint_url(nil, blueprint))

      expect(response).to have_http_status(:no_content)
    end

    it "forbids blueprint deletion without an appropriate role" do
      blueprint = FactoryGirl.create(:blueprint)
      api_basic_authorize

      delete(api_blueprint_url(nil, blueprint))

      expect(response).to have_http_status(:forbidden)
    end
  end
end
