
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

	static void Free(raxNode *n)
	{
		GC.free(n);
	}




};

struct raxItem
{
	raxNode *n;
	int		index;
}







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
		r.head = raxNode.NewComp(0 , false);

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

 



	void RecursiveFree(raxNode *n)
	{
		int numchildren = 0;
		if(n.iscompr)
		{
			numchildren = n.size > 0 ? 1: 0;
		}
		else
		{
			numchildren = n.size;
		}
		while(numchildren--){
			RecursiveFree(n.nextChild(numchildren));  
		}
		raxNode.Free(n);
		numnodes--;
	}

	static void Free(rax *r)
	{
		r.RecursiveFree(r.head);
		GC.free(r);
	}


	bool Remove(const ubyte[] s)
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem[] ts;
		uint index = 0;
		uint splitpos = 0;
		uint last = find(s , h , p , index , splitpos , ts);
		if(last > 0){
			log_error("remove " , cast(string)s , " " ,last);
			return false;
		}
		else{
			if(h.iskey) {
				numele--;
				h.iskey = false;
				// #1 empty
				if(h.size == 0)
				{

					if( p.iscompr)
					{
						if(p.iskey)
						{
							h.iskey = true;
							h.value = p.value;
							if(p == head)
							{
								head = h;
							
							}
							else
							{
								raxItem item = ts[$ - 2];
								item.n.nextChild(item.index , h);
							}
							numnodes -= 1;
							raxNode.Free(p);
							log_info("#####r0 0");
						}
						else // pp exist. & pp is non compr
						{
							//pp
							if( p == head)
							{
								head = h;
								numnodes -= 1;
								log_info("####r000");
							}
							else{
								raxItem t1 = ts[$ - 2];
								raxNode *r1 = ts[$ - 2].n;
								if( r1.size == 2){


									raxNode *pp = null;
									if(ts.length >= 3)
										pp = ts[$ - 3].n;
									bool ppCombine =  pp && pp.iscompr && !r1.iskey;
									raxNode *nh = r1.nextChild(r1.size - 1 - t1.index);
									bool nhCombie = nh.iscompr && !nh.iskey;



									if( ppCombine && nhCombie)
									{
										bool hasdata = pp.iskey && !pp.isnull;
										raxNode *u = raxNode.NewComp(pp.size + nh.size + 1 , hasdata);
										memcpy(u.str , pp.str , pp.size);
										memcpy(u.str + pp.size , r1.str + r1.size - 1 - t1.index , 1);
										memcpy(u.str + pp.size + 1 , nh.str ,  nh.size);

										u.iskey = pp.iskey;
										if(hasdata)
										{
											u.value = pp.value;
										}
										u.next( nh.next);
										if( pp == head)
										{
											head = u;
										}
										else{
											raxItem item = ts[$ - 4];
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(nh);
										raxNode.Free(pp);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 4;
										log_info("####r0 00");

									}
									else if(ppCombine)
									{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode *u = raxNode.NewComp(pp.size + 1 , hasdata);
										memcpy(u.str , pp.str , pp.size);
										memcpy(u.str + pp.size , p.str+ p.size - 1 - t1.index , 1);
										u.next(nh);
										u.iskey = r1.iskey;
										if(hasdata)
										{
											u.value = r1.value;
										}
										
										if( pp == head)
										{
											head = u;
										}
										else{
											raxItem item = ts[$ - 4];
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(pp);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 3;
										
										log_info("####r0 01");
									}
									else if(nhCombie)
									{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode* u = raxNode.NewComp(1 + nh.size , false);
										memcpy(u.str  , r1.str + r1.size - 1 - t1.index , 1);
										memcpy(u.str + 1,  nh.str , nh.size);
										u.iskey = r1.iskey;

										if(hasdata)
										{
											u.value = r1.value;
										}

										u.next(nh.next);
										
										if( r1 == head)
										{
											head = u;
										}
										else
										{
											raxItem item = ts[$ - 3];
											log_info(getStr(item.n));
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(nh);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 3;
										log_info("####r0 02");
									}
									else{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode *n = raxNode.NewComp(1 , hasdata);
										n.iskey = r1.iskey;
										if(hasdata)
											n.value = r1.value;
										n.str[0] = r1.str[r1.size - 1 - t1.index];
										n.next( r1.nextChild(r1.size - 1 - t1.index));
										
										if(r1 == head)
										{
											head = n;
										}
										else{
											raxItem item = ts[$ - 3];
											item.n.nextChild(item.index , n);
										}
										
										raxNode.Free(h);
										raxNode.Free(p);
										raxNode.Free(r1);
										numnodes -= 2;
										log_info("####r0 03");
									}


								}
								else if (r1.size > 2){

									bool hasdata = r1.iskey && !r1.isnull;
									raxNode *u = raxNode.New(r1.size - 1, hasdata);
									u.iskey = r1.iskey;
									if(hasdata)
									{
										u.value = r1.value;
									}
									
									log_info("index " , index , " " , r1.size);
									
									if( t1.index == 0)
									{
										memcpy(u.str , r1.str + 1 , r1.size - 1 );
									}
									else if(t1.index == r1.size - 1)
									{	
										memcpy(u.str , r1.str , r1.size - 1);
									}
									else
									{
										memcpy(u.str , r1.str  , t1.index);
										memcpy(u.str + t1.index  , r1.str + t1.index + 1, r1.size - t1.index -1);
									}

									log_info(getStr(u));

									for( uint i , j  = 0 ; i < r1.size ; )
									{
										if( i != t1.index)
											u.orgin[j++] = r1.orgin[i++];
										else
											i++;
									}

									if(r1 == head)
									{
										head = u;
									}
									else{
										raxItem i = ts[$ - 3];
										i.n.nextChild(i.index , u);
									}
									
									raxNode.Free(r1);
									raxNode.Free(h);
									raxNode.Free(p);
									numnodes -= 2;
									log_info("####r0 2");

								}
								else{
									log_info("####r0 y");
								}


							}



						}
					}
					else if(!p.iscompr)
					{
						// noncompr to compr
						log_info("p " , getStr(p));
						if(p.size == 2){
						
								raxNode *pp = ts[$ - 2].n;
								bool ppCombine = ts.length >= 2 && pp.iscompr && !p.iskey;
								raxNode *nh = p.nextChild(p.size - 1 - index);

								log_info("nh " , getStr(nh));
								bool nhCombie = nh.iscompr && !nh.iskey;
								
								log_info(ppCombine , " " , nhCombie);
								
								// #1 合并3个
								if( ppCombine && nhCombie)
								{
									bool hasdata = pp.iskey && !pp.isnull;
									raxNode *u = raxNode.NewComp(pp.size + nh.size + 1 , hasdata);
									memcpy(u.str , pp.str , pp.size);
									memcpy(u.str + pp.size , p.str + p.size - 1 - index , 1);
									memcpy(u.str + pp.size + 1 , nh.str ,  nh.size);

									u.iskey = pp.iskey;	
									if(hasdata)
										u.value = pp.value;

									u.next( nh.next);
									if( pp == head)
									{
										head = u;
									}
									else{
										raxItem item = ts[$ - 3];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(nh);
									raxNode.Free(pp);
									raxNode.Free(p);
									raxNode.Free(h);

									numnodes -= 3;

									log_info("####r1");
								}
								// #2 
								else if(ppCombine)
								{
									
									bool hasdata = pp.iskey && !pp.isnull;
									raxNode *u = raxNode.NewComp(pp.size + 1 , hasdata);
									memcpy(u.str , pp.str , pp.size);
									memcpy(u.str + pp.size , p.str+ p.size - 1 - index , 1);
									u.next(nh);
									u.iskey = pp.iskey;
									if(hasdata)
										u.value = pp.value; 
									
									if( pp == head)
									{
										head = u;
									}
									else{
										raxItem item = ts[$ - 3];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(pp);
									raxNode.Free(p);
									raxNode.Free(h);
									numnodes -= 2;

									log_info("####r2");
								}
								else if(nhCombie)
								{
									bool hasdata = p.iskey && !p.isnull;
									raxNode* u = raxNode.NewComp(1 + nh.size , hasdata);
									memcpy(u.str  , p.str + p.size - 1 - index , 1);
									memcpy(u.str + 1,  nh.str , nh.size);
									u.iskey = p.iskey;
									u.next(nh.next);
									if(hasdata)
										u.value = p.value;
									if( p == head)
									{
										head = u;
									}
									else
									{
										raxItem item = ts[$ - 2];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(nh);
									raxNode.Free(p);
									raxNode.Free(h);
									numnodes -= 2;
									log_info("####r3");
								}
								// p.iskey or no combine.
								else{
									bool hasdata = p.iskey && !p.isnull;
									raxNode *n = raxNode.NewComp(1 , hasdata);
									n.iskey = p.iskey;
									if(hasdata)
										n.value = p.value;
									n.str[0] = p.str[p.size - 1 - index];
									n.next( p.nextChild(p.size - 1 - index));
									
									if(p == head)
									{
										head = n;
									}
									else{
										raxItem item = ts[$ - 2];
										item.n.nextChild(item.index , n);
									}
									
									raxNode.Free(h);
									raxNode.Free(p);
									numnodes -= 1;
									log_info("#####r4");
							}

						}
						else if(p.size > 2){

							bool hasdata = p.iskey && !p.isnull;
							raxNode *u = raxNode.New(p.size - 1, hasdata);
							u.iskey = p.iskey;
							if(hasdata)
							{
								u.value = p.value;
							}

							log_info("index " , index , " " , p.size);
						
							if( index == 0)
							{
								memcpy(u.str , p.str + 1 , p.size - 1 );
							}
							else if(index == p.size - 1)
							{	
								memcpy(u.str , p.str , p.size - 1);
							}
							else
							{
								memcpy(u.str , p.str  , index);
								memcpy(u.str + index  , p.str + index + 1, p.size - index -1);
							}

							for( uint i , j  = 0 ; i < p.size ; )
							{
								if( i != index)
									u.orgin[j++] = p.orgin[i++];
								else
									i++;
							}

							if(p == head)
							{
								head = u;
							}
							else{
								raxItem item = ts[$ - 2];
								item.n.nextChild(item.index , u);
							}


							raxNode.Free(h);
							raxNode.Free(p);
							numnodes--;
							log_info("####rr");
						}
					}
				}
				// h.size > 0
				else{

					if(h.iscompr)
					{

						bool ppcombine = p.iscompr && !p.iskey;

						bool hasdata = p.iskey && !p.isnull;
						raxNode *u = raxNode.NewComp(p.size + h.size ,  hasdata);
						u.iskey = p.iskey;
						if(hasdata)
						{
							u.value = p.value;
						}

						memcpy(u.str , p.str , p.size);
						memcpy(u.str + p.size , h.str , h.size);
						u.next(h.next);
						if(p == head)
						{
							head = u;
						}
						else
						{
							raxItem item = ts[$ - 2];
							item.n.nextChild(item.index , u);
						}
						numnodes--;
						raxNode.Free(p);
						raxNode.Free(h);
						log_info("####rx");
					}
					else{
						log_info("####ry");
					}

				}


				return true;			
			}
			else{
				log_error(cast(string)s , " is not key " , getStr(h));
				return false;
			}
		}
	
	}

	//insert
	int Insert(const ubyte[] s , void *data )
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem [] ts;
		uint index = 0;
		uint splitpos = 0;
		numele++;
		uint last = find(s , h , p , index , splitpos , ts);

		log_info("find " ,cast(string)s , " last ",  last , " split " , splitpos ," index " , index);

		//没有找到该s.
		if (last > 0)
		{
			// #1 如果该树是空树.
			//
			//				'test'
			//		（） ----------->（'test'）
			//							 |	
			//							()
			//							
			if(p.size == 0)
			{
				raxNode *n = raxNode.NewComp(cast(uint)s.length , false);
				memcpy(n.str , s.ptr , s.length);

				p = raxNode.RenewComp(p , 0 , true);
				p.iskey = true;
				p.value = data;

				n.next = p;
				head = n;

				numnodes++;

				log_info("####1");
			}
			else
			{
					
					// #2 直到匹配到叶子节点，都没有匹配到，必须往该叶子节点后面加剩余的字符。
					//				'tester'
					//	("test") -------->	("test")
					//		|					|
					//		()				  ("er")
					//							|
					//							()
					if(h.size == 0)
					{
						//1 new comp node
						raxNode *n = raxNode.NewComp(last , true);
						memcpy(n.str , s[ $ - last .. $].ptr , last);
						n.iskey = true;
						n.value = h.value;

						h.value = data;
			
						n.next = h;
						p.next = n;
			
						numnodes++;
						log_info("####2");
					}
					//	#3	匹配到压缩节点，1 必须截断前部分。2 取原字符及压缩节点匹配字符构成 两个字符的 非压缩节点。 
					//			3 非压缩节点 两个子节点 分别指向 截断后半部分 及 原字符后半部分
					//
					//				'teacher'
					//	('test')---------------->('te')
					//		|						|
					//		(x)					  ['as']	u2
					//							   / \	
					//					u4 ('cher')  ('t') u3
					//						   /		\
					//					  u5 ()			(x)
					//
					else if(h.iscompr) {

						raxNode *u1;

						auto u2 = raxNode.New(2 , false);
						u2.str[0] = s[$ - last];
						u2.str[1] = h.str[splitpos];
						numnodes++;

						bool hasvalue = h.iskey && !h.isnull;
						if( splitpos > 0)
						{
							u1 = raxNode.NewComp(splitpos , hasvalue);
							memcpy(u1.str , h.str , splitpos);
							u1.iskey = h.iskey;
							if(hasvalue)
								u1.value = h.value;
							numnodes++;
						}
						else{
							u1 = u2;
							u1.iskey = h.iskey;
							if(hasvalue)
								u1.value = h.value;
						}


						uint u3_len = h.size - splitpos - 1;
						raxNode *u3;
						bool bcombine = false;
						if( u3_len > 0 )
						{
							//combin
							if(h.next.size > 0 && h.next.iscompr && !h.next.iskey)
							{
								u3 = raxNode.NewComp(u3_len + h.next.size , h.next.iskey && !h.next.isnull);
								memcpy(u3.str , h.str + splitpos + 1 , h.size - splitpos -1);
								memcpy(u3.str + h.size - splitpos - 1 , h.next.str , h.next.size);
								numnodes++;
								bcombine = true;

							}
							else
							{
								u3 = raxNode.NewComp(h.size - splitpos - 1 , false);
								memcpy(u3.str , h.str + splitpos + 1 ,h.size - splitpos -1);
								numnodes++;
							}
						}
						else
						{
							u3 = h.next;
						}
						

						//4
						uint u4_len = last - 1;
						raxNode *u4;
						
						//5
						auto u5 = raxNode.NewComp(0 , true);
						u5.iskey = true;
						u5.value = data;
						numnodes++;

						if(u4_len > 0)
						{		
							u4 = raxNode.NewComp(last - 1, false);
							memcpy(u4.str  , s.ptr + s.length - last + 1 , last - 1);
							numnodes++;
						}
						else{
							u4 = u5;
						}
						
						//relation
						if(u4_len > 0)
							u4.next = u5;

						if(bcombine)
						{
							u3.next = h.next.next;
							raxNode.Free(h.next);
							numnodes--;
						}
						else if( u3_len > 0)
						{
							u3.next = h.next;
						}	 	

						u2.nextChild(0 , u4);
						u2.nextChild(1 , u3);
						
						if(splitpos > 0)
							u1.next = u2;

						p.nextChild(index , u1);

						if( h == head)
							head = u1;
							
						raxNode.Free(h);
						numnodes--;

						log_info("####3");

				}
				// 	#4	都不匹配非压缩节点的任何子节点 1 增加该字符 2 截断原字符
				//	
				//					 'beer'				
				//			["tes"]	--------->	['tesb']
				//			/ / \ 				/ / \  \
				// 		  () () ()             () () () ('eer')
 				//											\
				//											()
				else{	

					bool hasdata = !h.isnull && h.iskey;
					auto i = raxNode.New( h.size + 1 , hasdata);
					i.iskey = h.iskey;
					i.isnull = h.isnull;
					if(hasdata)
					{
						h.value = i.value;
					}

					numnodes++;
					memcpy(i.str ,  h.str, h.size );
					i.str[h.size] = s[$ - last];
					memcpy(i.str + i.size  , h.str + h.size , h.size * (raxNode *).sizeof);


					auto u1_len = last - 1;
					raxNode *u1;


					auto u2 = raxNode.NewComp(0 , true);
					u2.value = data;
					u2.iskey = true;
					numnodes++;
					if( u1_len > 0)
					{
						u1 = raxNode.NewComp(u1_len , false);
						memcpy(u1.str , s.ptr  + s.length - last + 1  , u1_len);
						numnodes++;
						u1.next = u2;
					}
					else
					{
						u1 = u2;
					}

					i.nextChild(h.size , u1);
					p.nextChild(index , i);

					if(h == head)
						head = i;
					raxNode.Free(h);
					numnodes--;
					log_info("####4");
				}
			}

		}else{
			//	#5	完全匹配，只要改个值 即可。
			if(splitpos == 0)
			{
				bool hasdata = (h.iskey && !h.isnull);
				if(hasdata) {
					
					h.value = data;
					if(h.iskey)		//replaced
						numele--;
				}
				else{
					raxNode *u;
					if(h.iscompr)
						u = raxNode.RenewComp(h , h.size , true);
					else
						u = raxNode.Renew(h , h.size ,true);
					u.value = data;
					u.iskey = true;
					p.nextChild(index , u);
				}

				log_info("####5");

			}
			//	#6	完全匹配压缩节点前半部分。 分割即可。
			else if(h.iscompr) {

				bool hasdata = (h.iskey && !h.isnull);
				auto u1 = raxNode.NewComp(splitpos , hasdata);
				memcpy(u1.str , h.str , splitpos);
				u1.iskey = h.iskey;
				if(hasdata)
					u1.value = h.value;
				numnodes++;
			
				auto u2 = raxNode.NewComp(h.size - splitpos , true);
				memcpy(u2.str , h.str + splitpos , h.size - splitpos);
				u2.iskey = true;
				u2.value = data;
				numnodes++;
				u2.next = h.next;


				u1.next = u2;

				raxNode.Free(h);
				numnodes--;
				if(h == head)
				{
					head = u1;
				}
				else{
					p.nextChild(index , u1);
				}

				log_info("####6");
			}
		}

		return 0;
	}

	//remove

	//find
	uint find(const ubyte[] s , ref raxNode *r , ref raxNode *pr , ref uint index  , ref uint splitpos ,ref raxItem[] ts)
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
				index = 0;
				raxItem item;
				item.n = pr;
				item.index = index;
				ts ~= item;
				return find(s[(*pr).size .. $] , r , pr, index , splitpos , ts);
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
				if( *p == s[0])
					break;
				p++;
			}


			uint i = cast(uint)(p - r.str);
			if( p == end)
			{	
				splitpos = i;
				return cast(uint)s.length;
			}
			else
			{
				pr = r;
				index = i ;
				r = r.nextChild(index);	
				raxItem item;
				item.n = pr;
				item.index = index;
				ts ~= item;
				return find(s[1 .. $] , r , pr , index , splitpos , ts);
			}
		}

	}


	string getStr(raxNode *h)
	{
		string str;
		for(uint i = 0 ; i < h.size ; i++)
			str ~= h.str[i];
		return str;
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
			{	
				Recursiveshow(n.nextChild(i) , level);
			}
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

		writef("\n");
	}


private:


};








unittest{

	void test1()
	{
		rax *r = rax.New();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		void *p3 = cast(void *)0x3;
		void *p4 = cast(void *)0x4;
		void *p5 = cast(void *)0x5;
		void *p6 = cast(void *)0x6;
		void *p7 = cast(void *)0x7;
		void *p8 = cast(void *)0x8;
		void *p9 = cast(void *)0x9;
		void *p10 = cast(void *)0x10;
		void *p11 = cast(void *)0x11;
		void *p12 = cast(void *)0x12;
		void *p13 = cast(void *)0x13;
		void *p14 = cast(void *)0x14;
		void *p15 = cast(void *)0x15;
		void *p16 = cast(void *)0x16;
		void *p17 = cast(void *)0x17;
		void *p18 = cast(void *)0x18;
		void *p19 = cast(void *)0x19;
		void *p20 = cast(void *)0x20;
		void *p21 = cast(void *)0x21;
		void *p22 = cast(void *)0x22;

		r.Insert(cast(ubyte[])"test" , p1);
		r.Insert(cast(ubyte[])"tester" , p2);
		r.Insert(cast(ubyte[])"teacher" , p3);
		r.Insert(cast(ubyte[])"teachee" , p4);
		r.Insert(cast(ubyte[])"testee" , p5);

		r.Insert(cast(ubyte[])"testor" , p6);
		r.Insert(cast(ubyte[])"tech" , p7);
		r.Insert(cast(ubyte[])"teck" , p7);
		r.Insert(cast(ubyte[])"tea" , p8);
		r.Insert(cast(ubyte[])"tes" , p9);
		r.Insert(cast(ubyte[])"teache" , p10);

		r.Insert(cast(ubyte[])"teach" , p11);
		r.Insert(cast(ubyte[])"t" , p12);
		r.Insert(cast(ubyte[])"tttttttt" , p13);
		r.Insert(cast(ubyte[])"1" , p13);
		r.Insert(cast(ubyte[])"t2ttt4tttt" , p14);
		r.Insert(cast(ubyte[])"tt3t4ttttt" , p15);

		r.Insert(cast(ubyte[])"abcd" , p16);
		r.Insert(cast(ubyte[])"dsdas" , p17);
		r.Insert(cast(ubyte[])"test" , p18);
		r.Insert(cast(ubyte[])"tea1" , p19);
		r.Insert(cast(ubyte[])"tea3" , p20);


		r.Insert(cast(ubyte[])"te4a" , p21);
		r.Insert(cast(ubyte[])"t2ttt4t" , p22);

		r.show();

		r.Remove(cast(ubyte[])"test" );
		r.Remove(cast(ubyte[])"tester" );
		r.Remove(cast(ubyte[])"teacher" );
		r.Remove(cast(ubyte[])"teachee" );
		r.Remove(cast(ubyte[])"testee" );

		r.Remove(cast(ubyte[])"testor" );
		r.Remove(cast(ubyte[])"tech" );
		r.Remove(cast(ubyte[])"teck" );
		r.Remove(cast(ubyte[])"tea" );
		r.Remove(cast(ubyte[])"tes" );
		r.Remove(cast(ubyte[])"teache");
	
		r.Remove(cast(ubyte[])"teach" );
		r.Remove(cast(ubyte[])"t" );
		r.Remove(cast(ubyte[])"tttttttt" );
		r.Remove(cast(ubyte[])"1" );
		r.Remove(cast(ubyte[])"t2ttt4tttt" );
		r.Remove(cast(ubyte[])"tt3t4ttttt");

		r.Remove(cast(ubyte[])"abcd" );
		r.Remove(cast(ubyte[])"dsdas" );
		r.Remove(cast(ubyte[])"tea1" );
		r.Remove(cast(ubyte[])"tea3" );

		r.Remove(cast(ubyte[])"te4a" );
		r.Remove(cast(ubyte[])"t2ttt4t" );

		r.show();

	}

	void test2()
	{
		rax *r = rax.New();
		r.show();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		r.Insert(cast(ubyte[])"test" , p1);
		r.show();
		r.Insert(cast(ubyte[])"tester" , p2);
		r.show();
		r.Remove(cast(ubyte[])"test" );
		r.show();
		r.Remove(cast(ubyte[])"tester");
		r.show();
	}

	void test3()
	{
		rax *r = rax.New();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		void *p3 = cast(void *)0x3;
		void *p4 = cast(void *)0x4;
		r.Insert(cast(ubyte[])"te" , p1);
		r.Insert(cast(ubyte[])"test" , p2);
		r.Insert(cast(ubyte[])"tester" , p3);
		r.Insert(cast(ubyte[])"testering" , p4);
		r.show();
		r.Remove(cast(ubyte[])"tester");
		r.show();
		r.Remove(cast(ubyte[])"te");
		r.show();
		r.Remove(cast(ubyte[])"test");
		r.Remove(cast(ubyte[])"testering");
		r.show();
	}

	void test4(){

		rax *r = rax.New();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		void *p3 = cast(void *)0x3;
		void *p4 = cast(void *)0x4;
		void *p5 = cast(void *)0x5;
		void *p6 = cast(void*)0x6;
		void *p7 = cast(void *)0x7;
		void *p8 = cast(void *)0x8;

		r.Insert(cast(ubyte[])"tt" , p1);
		r.Insert(cast(ubyte[])"t1" , p2);
		r.Insert(cast(ubyte[])"tea" , p3);
		r.Insert(cast(ubyte[])"test" , p4);
		r.Insert(cast(ubyte[])"tester" , p5);
		r.Insert(cast(ubyte[])"fuck" , p6);
		r.Insert(cast(ubyte[])"fucking" , p7);
		r.Insert(cast(ubyte[])"you" , p8);


		r.Remove(cast(ubyte[])"tt" );

		r.Remove(cast(ubyte[])"t1" );
	
	
		r.Remove(cast(ubyte[])"tea");
	
		r.Remove(cast(ubyte[])"test" );



		r.Remove(cast(ubyte[])"tester" );
		r.Remove(cast(ubyte[])"fuck" );

		r.Remove(cast(ubyte[])"fucking" );
		r.show();
		r.Remove(cast(ubyte[])"you");
		r.show();


	}
	test1();
	test4();
	test2();
	test3();
}

