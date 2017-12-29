
module zhang2018.radix;

import std.stdio;
import core.memory;
import core.stdc.string;

import zhang2018.common.Log;








// vitrual struct.

struct raxNode
{
	uint args;
			  //	1 	iskey	
			  //	1	isnull	don't store it 
			  //	1	iscompr 
			  //	29	size

	//void *data;

	//	node is not compr
	//  [abc][a-ptr][b-ptr][c-ptr](value-ptr?)
	//	
	//  node is compr
	//	[xyz][z-ptr](value-ptr?)
pragma(inline, true):

	@property char *str()
	{
		return cast(char*)(&this + 1);
	}

	@property  bool iskey()
	{
		return cast(bool)(args & 0x80000000);
	}
	
	 @property bool iskey(bool value)
	{
		if(value)
			args = args | 0x80000000;
		else
			args = args & (~0x80000000);

		return value;
	}

	@property bool isnull()
	{
		return cast(bool)(args & 0x40000000);
	}
	
	@property bool isnull( bool value)
	{
		if(value)
			args = args| 0x40000000;
		else
			args = args & (~0x40000000);

		return value;
	}

	@property bool iscompr()
	{
		return cast(bool)(args & 0x20000000);
	}
	
	@property bool iscompr( bool value)
	{
		if(value)
			args = args | 0x20000000;
		else
			args = args & (~0x20000000);
		
		return value;
	}



	
	 @property uint size()
	{
		return args & 0x1FFFFFFF;
	}

	 @property uint size(uint value)
	{
		uint v = args & (~0x1FFFFFFF);
		v += value;
		args = v;
		return value;
	}

	@property raxNode** orgin()
	{
		return cast(raxNode**)(str+size);
	}

	@property raxNode * next()
	{
		return *orgin;
	}

	@property raxNode *next(raxNode *n)
	{
		*orgin = n;
		return n;
	}




	@property raxNode * nextChild(uint index)
	{
		return orgin[index];
	}

	@property raxNode *nextChild(uint index , raxNode *n)
	{
		orgin[index] = n;
		return n;
	}



	@property void *value()
	{
		if(iscompr)
			return orgin[1];
		else
			return orgin[size];
	}


	@property void * value(void *v)
	{
		if(iscompr)
			orgin[1] = cast(raxNode *)v;
		else
			orgin[size] = cast(raxNode *)v;
		return v;
	}




	//alloc non-compr node
	static raxNode* New(uint children , bool hasdata)
	{
		long nodesize = raxNode.sizeof + children + (raxNode*).sizeof * children;
		if(hasdata)
			nodesize += (void*).sizeof;

		raxNode *n = cast(raxNode*)GC.malloc(nodesize);
		if( n == null) return null;

		n.iskey = false;
		n.isnull = false;
		n.iscompr = false;
		n.size = children;

		return n;
	}

	static raxNode *NewComp(uint length , bool hasdata)
	{
		long nodesize = raxNode.sizeof + length + (raxNode *).sizeof;
		if(hasdata)
			nodesize += (void *).sizeof;

		raxNode *n = cast(raxNode*)GC.malloc(nodesize);
		if( n == null) return null;

		n.iskey = false;
		n.isnull = false;
		n.iscompr = true;
		n.size = length;


		return n;

	}


	static raxNode *Renew(raxNode *n , uint children , bool hasdata)
	{
		long nodesize = raxNode.sizeof + children + (raxNode*).sizeof * children;
		if(hasdata)
			nodesize += (void *).sizeof;

		auto node = cast(raxNode*)GC.realloc(n , nodesize);
		if(node == null) return null;
		node.iscompr = false;
		return node;
	}


	static raxNode *RenewComp(raxNode *n , uint length , bool hasdata)
	{
		long nodesize= raxNode.sizeof + length + (raxNode*).sizeof * length;
		if(hasdata)
			nodesize += (void *).sizeof;

		auto node = cast(raxNode*) GC.realloc(n , nodesize);
		if( node == null) return null;
		node.iscompr = true;
		return node;
	}





};



struct rax
{
	raxNode 	*head;
	long	 	numele;
	long		numnodes;

	static rax * New()
	{
		rax *r = cast(rax *)GC.malloc(rax.sizeof);
		if (r == null) return null;
		
		r.numele = 0;
		r.numnodes = 1;
		r.head = raxNode.New(0 , true);

		if (r.head == null)
		{
			Free(r);
			return null;
		}
		else
		{
			return r;
		}
	}

 



	static void Free(rax *r)
	{
		//next
	}


	//insert
	int Insert(const ubyte[] s , void *data )
	{
		raxNode *h = head;
		raxNode *p = head;
		uint splitpos = 0;
		uint last = find(s , h , p , splitpos);

		log_info("find " ,cast(string)s , " ",  last , " " , splitpos ," ", p ," " , h);


		//not found
		if (last > 0)
		{

			// #1
			if(p.size == 0)
			{

				//1 new comp node
				raxNode *n = raxNode.NewComp(cast(uint)s.length , false);
				memcpy(n.str , s.ptr , s.length);

				//2 modify father node
				p = raxNode.Renew(p , 0 , true);
				p.iskey = true;
				p.value = data;
				//3 relink
				n.next = p;

				head = n;

				//4 inc
				numele++;
				numnodes++;
				return 0;
			}


			if(p.size > 0 )
			{
				if(p.iscompr)	// 压缩节点
				{
					//匹配到最后
					// #2
					if(h.size == 0)
					{
						bool ishead = (p == head);

						//1 new comp node
						raxNode *n = raxNode.NewComp(last , true);
						memcpy(n.str , s[ $ - last .. $].ptr , last);
						n.iskey = true;
						n.value = h.value;

						// change value
						h.value = data;

						
						n.next = h;
						p.next = n;

						if(ishead)
							head = p;

						numele++;
						numnodes++;
					}
					//
					else {
						//#3
						//1 new comp node
						bool hasvalue = h.iskey && !h.isnull;
						auto u1 = raxNode.NewComp(splitpos , hasvalue);
						memcpy(u1.str , h.str , splitpos);
						u1.iskey = h.iskey;
						u1.value = h.value;

						//2 add non-comp node
						auto u2 = raxNode.New(2 , false);
						u2.str[0] = h.str[splitpos];
						u2.str[1] = s[$ - last];

						//3
						auto u3 = raxNode.NewComp(h.size - splitpos , false);
						memcpy(u3.str , h.str + splitpos ,h.size - splitpos);

						//4
						auto u4 = raxNode.NewComp(last , false);
						memcpy(u4.str  , s.ptr + s.length - last , last);

						//relation



					}

				}
			}
			else{


			}

		}
	

		return 0;



	}

	//remove

	//find
	uint find(const ubyte[] s , ref raxNode *r , ref raxNode *pr, ref uint splitpos)
	{
		//find it
		
		if ( s == null)
		{	
			return 0;
		}

		if( r.size == 0)
		{	

			return cast(uint)s.length;
		}
			
		if ( r.iscompr )	//is compr
		{
			char *p = r.str;
			uint i = 0;
			for( i = 0 ; i < r.size && i < s.length ; i++)
			{
				if(p[i] != s[i])
					break;
			}


			if( i == r.size)
			{	
				pr = r;
				r = r.next;		
				return find(s[pr.size .. $] , r , pr , splitpos);
			}
			else
			{
				splitpos = i;
				return cast(uint)s.length - i;
			}
		}
		else {

			char *p = r.str;
			char *end = r.str + r.size;
			while(p != end)
			{
				if( *p++ == s[0])
					break;
			}


			uint i = cast(uint)(p - r.str);
			if( p == end)
			{	
				splitpos = i;
				return cast(uint)s.length - i;
			}
			else
			{
				pr = r;
				r = r.nextChild(splitpos);		
				return find(s[1 .. $] , r , pr  , i);
			}
		}

	}



	void Recursiveshow(raxNode *n , int level)
	{
	
		show(n , level);

		if(n.size == 0)
			return ;
			
		if(n.iscompr)
		{
			Recursiveshow(n.next , ++level);
		}
		else
		{
			++level;
			for(uint i = 0 ; i < n.size ; i++)
				Recursiveshow(n.nextChild(i) , level);
		}
	}

	void show(raxNode *n , int level)
	{
		for(uint i = 0 ; i < level ; i++)
			write("\t");

		write("key:" , n.iskey  , n.iscompr ? " (" : " [");

		for(uint i = 0 ; i < n.size ; i++)
			write(n.str[i]);

		write(n.iscompr ? ") ":"] " ,  (n.iskey && !n.isnull)?n.value:null , "\n");
	}

	void show()
	{
		raxNode *p = head;
		writef("numele:%d numnodes:%d\n" , numele , numnodes);


		Recursiveshow(p ,0);
	}


private:


};








unittest{




	rax *r = rax.New();
	void *p1 = cast(void *)0x1;
	void *p2 = cast(void*)0x2;
	void *p3 = cast(void *)0x3;
	r.Insert(cast(ubyte[])"test" , p1);
	r.Insert(cast(ubyte[])"tester" , p2);
	//r.Insert(cast(ubyte[]) "testee" , p3);
	r.show();
}

