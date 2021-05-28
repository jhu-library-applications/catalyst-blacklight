# Helpers for dealing with CQL queries
module CqlHelper
  def reformatted_cql_search(params:)
    query = params[:q]
    facets = params[:f]

    reformatted_q = case query
                    when /title = "\\"(.*)\\"" AND author = \"(.*)\"/
                      captures = query.match(/title = "\\"(.*)\\"" AND author = \"(.*)\"/).captures

                      { q: "#{captures[0]} #{captures[1]}", search_field: 'all_fields', f: facets }
                    when /title = "\\"(.*)\\"\"/
                      { q: query.match(/title = "\\"(.*)\\"\"/).captures[0], search_field: 'title', f: facets }
                    when /\Aauthor = "\\"(.*)\\"\"/
                      { q: query.match(/author = "\\"(.*)\\"\"/).captures[0], search_field: 'author', f: facets }
                    else
                      query
                    end
    reformatted_q
  end
end
