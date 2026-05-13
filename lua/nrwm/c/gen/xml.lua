local M={}

---@class nrwm.xml.elem
---@field tag string
---@field attr table<string,string>
---@field content string
---@field children nrwm.xml.elem[]

---@param node TSNode
---@param nth integer
---@param type_ string|string[]
---@return TSNode
local function get_child_assert_type(node,nth,type_)
  local cnode
  local count=0
  while count<nth do
    cnode=assert(node:named_child(count))
    if cnode:type()=='Comment' then
      nth=nth+1
    end
    count=count+1
  end
  if type(type_)=='table' then
    assert(vim.list_contains(type_,cnode:type()))
  else
    assert(type_==cnode:type())
  end
  return cnode
end

local function named_child_count_no_comment(node)
  local count=0
  for i=0,node:named_child_count()-1 do
    if node:named_child(i):type()~='Comment' then
      count=count+1
    end
  end
  return count
end

---@param node TSNode
---@param source string
---@return nrwm.xml.elem
local function parse(node,source)
  local function text(node_)
    return vim.treesitter.get_node_text(node_,source)
  end
  local tag_node=get_child_assert_type(node,1,{'STag','EmptyElemTag'})
  local tag_name=text(get_child_assert_type(tag_node,1,'Name'))
  local attrs={}
  for i=2,named_child_count_no_comment(tag_node) do
    local attr_node=get_child_assert_type(tag_node,i,'Attribute')
    local key=text(get_child_assert_type(attr_node,1,'Name'))
    local val=text(get_child_assert_type(attr_node,2,'AttValue'))
    attrs[key]=assert(val:match('^"(.*)"$'))
  end
  if tag_node:type()=='EmptyElemTag' then
    return {tag=tag_name,attr=attrs,children={},content=''}
  end
  local content_node=get_child_assert_type(node,2,'content')
  local content=''
  local children={}
  for i=1,named_child_count_no_comment(content_node) do
    local cnode=get_child_assert_type(content_node,i,{'CharData','element'})
    if cnode:type()=='element' then
      table.insert(children,parse(cnode,source))
    elseif vim.trim(text(cnode))~='' then
      content=content..vim.trim(text(cnode))
    end
  end

  return {
    tag=tag_name,
    attr=attrs,
    children=children,
    content=content
  }
end

function M.parse(source)
  local parser=vim.treesitter.get_string_parser(source,'xml')
  local root=assert(parser:parse(true))[1]:root()
  local root_elem=assert(root:field('root')[1])
  return parse(root_elem,source)
end

return M
